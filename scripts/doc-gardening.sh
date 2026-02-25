#!/usr/bin/env bash
# doc-gardening.sh — nightly scan for stale/broken docs. Opens fix-up PRs.
#
# Designed to run in CI (via doc-gardening.yml) with GH_TOKEN and gh CLI.
# Can also run locally for a dry-run report.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT=""
PROBLEMS=0
DRY_RUN="${DRY_RUN:-false}"

add_problem() {
    REPORT="${REPORT}\n- $1"
    PROBLEMS=$((PROBLEMS + 1))
}

NOW=$(date +%s)
STALE_DAYS=90

# -----------------------------------------------------------------------
# 1. Stale documentation files
# -----------------------------------------------------------------------
echo "Scanning for stale documentation..."
while IFS= read -r mdfile; do
    mod_time=$(stat -c %Y "$mdfile" 2>/dev/null || stat -f %m "$mdfile" 2>/dev/null || echo "$NOW")
    age_days=$(( (NOW - mod_time) / 86400 ))
    if [[ $age_days -gt $STALE_DAYS ]]; then
        rel="${mdfile#"$REPO_ROOT"/}"
        add_problem "**Stale** (\`$age_days\` days): \`$rel\`"
    fi
done < <(find "$REPO_ROOT/docs" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/ARCHITECTURE.md" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# 2. Broken cross-links in all markdown files
# -----------------------------------------------------------------------
echo "Scanning for broken cross-links..."
while IFS= read -r mdfile; do
    rel_md="${mdfile#"$REPO_ROOT"/}"
    dir_of_file="$(dirname "$mdfile")"
    while IFS= read -r link; do
        target="${link%%#*}"
        target="${target%%)*}"
        [[ -z "$target" || "$target" == http* || "$target" == mailto* ]] && continue
        resolved="$dir_of_file/$target"
        if [[ ! -e "$resolved" ]]; then
            add_problem "**Broken link**: \`$rel_md\` -> \`$target\`"
        fi
    done < <(grep -oP '\]\(\K[^)]+' "$mdfile" 2>/dev/null || true)
done < <(find "$REPO_ROOT" -maxdepth 1 -name '*.md' -type f 2>/dev/null; find "$REPO_ROOT/docs" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# 3. Code-vs-docs drift: check if documented source files still exist
# -----------------------------------------------------------------------
echo "Scanning for code-vs-docs drift..."

# Extract backtick-quoted file paths from ARCHITECTURE.md and AGENTS.md
for doc in "$REPO_ROOT/ARCHITECTURE.md" "$REPO_ROOT/AGENTS.md"; do
    [[ ! -f "$doc" ]] && continue
    doc_name="$(basename "$doc")"
    while IFS= read -r path; do
        [[ "$path" == *'*'* || "$path" == *'{'* ]] && continue
        [[ "$path" == vendor/* ]] && continue
        [[ "$path" == *friscy.wasm* || "$path" == *rootfs.tar* || "$path" == *rv2wasm_jit* ]] && continue
        [[ "$path" == *claude-repl.ckpt* ]] && continue
        trimmed="${path%/}"
        if [[ ! -e "$REPO_ROOT/$trimmed" ]]; then
            add_problem "**Drift**: \`$doc_name\` references \`$path\` which no longer exists"
        fi
        # shellcheck disable=SC2016
    done < <(grep -oP '`[a-zA-Z][a-zA-Z0-9_/.\-]+\.(ts|tsx|js|hpp|cpp|rs|toml|json|html|sh)`' "$doc" 2>/dev/null | tr -d '`' | sort -u)
done

# -----------------------------------------------------------------------
# 4. Check documented exports still exist in source
# -----------------------------------------------------------------------
echo "Scanning for missing documented exports..."

check_drift() {
    local file="$1" symbol="$2"
    if [[ -f "$REPO_ROOT/$file" ]]; then
        if ! grep -q "$symbol" "$REPO_ROOT/$file" 2>/dev/null; then
            add_problem "**Missing export**: \`$file\` no longer contains \`$symbol\`"
        fi
    else
        add_problem "**Missing file**: \`$file\` referenced in docs but deleted"
    fi
}

check_drift "src/lib/FriscyMachine.ts" "async boot"
check_drift "src/lib/FriscyMachine.ts" "PackageManager"
check_drift "src/workers/emulator.worker.ts" "checkpointData"
check_drift "friscy-bundle/overlay.js" "computeDelta"
check_drift "friscy-bundle/overlay.js" "mergeTars"
check_drift "src/lib/PackageManager.ts" "applyLayers"

# -----------------------------------------------------------------------
# 5. Empty doc files
# -----------------------------------------------------------------------
echo "Checking for empty documentation files..."
while IFS= read -r mdfile; do
    if [[ ! -s "$mdfile" ]]; then
        rel="${mdfile#"$REPO_ROOT"/}"
        add_problem "**Empty**: \`$rel\`"
    fi
done < <(find "$REPO_ROOT/docs" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# 6. Orphaned docs (not linked from any root doc)
# -----------------------------------------------------------------------
echo "Checking for orphaned docs..."
while IFS= read -r mdfile; do
    rel="${mdfile#"$REPO_ROOT"/}"
    basename_md="$(basename "$mdfile")"
    # Check if any root-level md or docs/ index mentions this file
    found=false
    for root_md in "$REPO_ROOT/README.md" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/ARCHITECTURE.md"; do
        if grep -q "$basename_md\|$rel" "$root_md" 2>/dev/null; then
            found=true; break
        fi
    done
    if [[ "$found" == "false" ]]; then
        # Check if linked from a sibling or parent doc
        parent_dir="$(dirname "$mdfile")"
        if find "$parent_dir" -maxdepth 1 -name '*.md' -not -name "$basename_md" -exec grep -l "$basename_md" {} + &>/dev/null; then
            found=true
        fi
    fi
    if [[ "$found" == "false" ]]; then
        add_problem "**Orphaned**: \`$rel\` is not linked from any root doc"
    fi
done < <(find "$REPO_ROOT/docs" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# Report
# -----------------------------------------------------------------------
echo ""
echo "=== Doc Gardening Report ==="
echo "Problems found: $PROBLEMS"

if [[ $PROBLEMS -eq 0 ]]; then
    echo "All documentation is healthy."
    exit 0
fi

echo -e "$REPORT"

# -----------------------------------------------------------------------
# GitHub Actions: open or update a fix-up PR
# -----------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
    echo "(Dry run — skipping GitHub actions)"
    exit 1
fi

if [[ -n "${GH_TOKEN:-}" ]] && command -v gh &>/dev/null; then
    DATE=$(date -u +%Y-%m-%d)
    _BRANCH="doc-gardening/$DATE"

    BODY="## Doc Gardening Report ($DATE)

Found **$PROBLEMS** problem(s) that need attention:
$(echo -e "$REPORT")

---
*Auto-generated by \`scripts/doc-gardening.sh\`*"

    # Check for existing open issue first
    EXISTING_ISSUE=$(gh issue list --label "doc-gardening" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null || echo "")

    if [[ -n "$EXISTING_ISSUE" ]]; then
        gh issue comment "$EXISTING_ISSUE" --body "$BODY"
        echo "Updated existing issue #$EXISTING_ISSUE"
    else
        gh issue create \
            --title "Doc gardening: $PROBLEMS problem(s) found ($DATE)" \
            --body "$BODY" \
            --label "doc-gardening,documentation" 2>/dev/null || true
        echo "Created new gardening issue."
    fi
else
    echo "(No GH_TOKEN — skipping GitHub issue creation)"
fi

exit 1
