#!/usr/bin/env bash
# docs-lint.sh — validate the AEON knowledge base structure and cross-links.
# Runs in CI on every push/PR touching docs or source. Exit 1 = failures found.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0
WARNS=0

fail() { echo "::error::$1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "::warning::$1"; WARNS=$((WARNS + 1)); }

# -----------------------------------------------------------------------
# 1. Required root files
# -----------------------------------------------------------------------
echo "=== Checking required root files ==="
for f in AGENTS.md ARCHITECTURE.md README.md; do
    if [[ ! -f "$REPO_ROOT/$f" ]]; then
        fail "Required root file missing: $f"
    fi
done

# -----------------------------------------------------------------------
# 2. Required directories
# -----------------------------------------------------------------------
echo "=== Checking required directories ==="
REQUIRED_DIRS=(docs docs/assets docs/exec-plans runtime src src/lib src/workers friscy-bundle scripts)
for d in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$REPO_ROOT/$d" ]]; then
        fail "Required directory missing: $d/"
    fi
done

# -----------------------------------------------------------------------
# 3. ARCHITECTURE.md file references must exist
# -----------------------------------------------------------------------
echo "=== Checking ARCHITECTURE.md file references ==="
while IFS= read -r path; do
    # Skip wildcards, vendor, large binaries
    [[ "$path" == *'*'* || "$path" == *'{'* ]] && continue
    [[ "$path" == vendor/* ]] && continue
    [[ "$path" == *friscy.wasm* || "$path" == *rootfs.tar* || "$path" == *rv2wasm_jit* ]] && continue
    [[ "$path" == *claude-repl.ckpt* ]] && continue
    # Skip bare filenames (no directory separator) — they're relative within sections
    [[ "$path" != */* ]] && continue
    if [[ ! -e "$REPO_ROOT/$path" ]]; then
        fail "ARCHITECTURE.md references '$path' but it does not exist"
    fi
# shellcheck disable=SC2016
done < <(grep -oP '`[a-zA-Z][a-zA-Z0-9_/.\-]+\.(ts|tsx|js|hpp|cpp|rs|toml|json|html|css|wasm|txt|md|yml|ckpt|sh)`' "$REPO_ROOT/ARCHITECTURE.md" 2>/dev/null | tr -d '`' | sort -u)

# -----------------------------------------------------------------------
# 4. ARCHITECTURE.md must mention key components
# -----------------------------------------------------------------------
echo "=== Checking ARCHITECTURE.md covers key systems ==="
KEY_COMPONENTS=(
    "checkpoint"
    "overlay"
    "FriscyMachine"
    "PackageManager"
    "emulator.worker"
    "SharedArrayBuffer"
    "Web Lock"
    "libriscv"
)
for component in "${KEY_COMPONENTS[@]}"; do
    if ! grep -qi "$component" "$REPO_ROOT/ARCHITECTURE.md"; then
        fail "ARCHITECTURE.md does not mention: $component"
    fi
done

# -----------------------------------------------------------------------
# 5. AGENTS.md code layout paths must exist
# -----------------------------------------------------------------------
echo "=== Checking AGENTS.md code layout paths ==="
while IFS= read -r path; do
    [[ "$path" == *'*'* || "$path" == *'{'* ]] && continue
    [[ "$path" == vendor/* ]] && continue
    # Skip bare names without directory separator
    [[ "$path" != */* ]] && continue
    trimmed="${path%/}"
    if [[ ! -e "$REPO_ROOT/$trimmed" ]]; then
        fail "AGENTS.md references '$path' but it does not exist"
    fi
# shellcheck disable=SC2016
done < <(sed -n '/## Code Layout/,/^## /p' "$REPO_ROOT/AGENTS.md" | grep -oP '`[a-zA-Z][a-zA-Z0-9_/.\-]+/?`' | tr -d '`' | sort -u)

# -----------------------------------------------------------------------
# 6. Key source exports match documentation claims
# -----------------------------------------------------------------------
echo "=== Checking documented exports exist in source ==="

check_export() {
    local file="$1" symbol="$2" doc="$3"
    if [[ -f "$REPO_ROOT/$file" ]]; then
        if ! grep -q "$symbol" "$REPO_ROOT/$file" 2>/dev/null; then
            fail "$doc says '$file' has '$symbol' but it's not found"
        fi
    fi
}

# FriscyMachine
check_export "src/lib/FriscyMachine.ts" "async boot" "ARCHITECTURE.md"
check_export "src/lib/FriscyMachine.ts" "_boot" "ARCHITECTURE.md"
check_export "src/lib/FriscyMachine.ts" "terminate" "ARCHITECTURE.md"
check_export "src/lib/FriscyMachine.ts" "PackageManager" "ARCHITECTURE.md"

# Worker checkpoint support
check_export "src/workers/emulator.worker.ts" "checkpointData" "ARCHITECTURE.md"
check_export "src/workers/emulator.worker.ts" "load-checkpoint" "ARCHITECTURE.md"

# overlay.js exports
check_export "friscy-bundle/overlay.js" "computeDelta" "ARCHITECTURE.md"
check_export "friscy-bundle/overlay.js" "applyDelta" "ARCHITECTURE.md"
check_export "friscy-bundle/overlay.js" "mergeTars" "ARCHITECTURE.md"
check_export "friscy-bundle/overlay.js" "createSession" "ARCHITECTURE.md"
check_export "friscy-bundle/overlay.js" "saveOverlay" "ARCHITECTURE.md"

# PackageManager
check_export "src/lib/PackageManager.ts" "applyLayers" "ARCHITECTURE.md"
check_export "src/lib/PackageManager.ts" "loadManifest" "ARCHITECTURE.md"

# checkpoint.hpp
if [[ ! -f "$REPO_ROOT/runtime/checkpoint.hpp" ]]; then
    fail "ARCHITECTURE.md documents checkpoint.hpp but file is missing"
fi

# -----------------------------------------------------------------------
# 7. Internal markdown links
# -----------------------------------------------------------------------
echo "=== Checking internal markdown links ==="
for md in "$REPO_ROOT/README.md" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/ARCHITECTURE.md"; do
    [[ ! -f "$md" ]] && continue
    while IFS= read -r link; do
        [[ "$link" == http* || "$link" == '#'* || -z "$link" || "$link" == mailto* ]] && continue
        link_path="${link%%#*}"
        [[ -z "$link_path" ]] && continue
        target="$(dirname "$md")/$link_path"
        if [[ ! -e "$target" ]]; then
            fail "$(basename "$md") has broken link: $link"
        fi
    done < <(grep -oP '\]\(\K[^)]+' "$md" 2>/dev/null || true)
done

# -----------------------------------------------------------------------
# 8. No empty doc files
# -----------------------------------------------------------------------
echo "=== Checking for empty documentation files ==="
while IFS= read -r mdfile; do
    if [[ ! -s "$mdfile" ]]; then
        rel="${mdfile#"$REPO_ROOT"/}"
        fail "Empty documentation file: $rel"
    fi
done < <(find "$REPO_ROOT/docs" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# 9. README directory tree vs actual directories
# -----------------------------------------------------------------------
echo "=== Checking README.md directory tree ==="
# Only check top-level dirs (lines starting with ├── or └── at column 0-1 in the tree)
while IFS= read -r dir; do
    dir="${dir%/}"
    [[ -z "$dir" ]] && continue
    if [[ ! -d "$REPO_ROOT/$dir" ]]; then
        fail "README.md directory tree lists '$dir/' but it does not exist"
    fi
# shellcheck disable=SC2016
done < <(sed -n '/^```$/,/^```$/p' "$REPO_ROOT/README.md" | grep -P '^[├└]' | grep -oP '(?:├──|└──)\s+(\S+?)/' | sed 's/[├└── ]//g' | tr -d '/' | sort -u)

# -----------------------------------------------------------------------
# 10. Freshness (warn only)
# -----------------------------------------------------------------------
echo "=== Checking doc freshness ==="
NOW=$(date +%s)
STALE_DAYS=90
while IFS= read -r mdfile; do
    mod_time=$(stat -c %Y "$mdfile" 2>/dev/null || stat -f %m "$mdfile" 2>/dev/null || echo "$NOW")
    age_days=$(( (NOW - mod_time) / 86400 ))
    if [[ $age_days -gt $STALE_DAYS ]]; then
        rel="${mdfile#"$REPO_ROOT"/}"
        warn "$rel has not been updated in $age_days days"
    fi
done < <(find "$REPO_ROOT/docs" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/ARCHITECTURE.md" -name '*.md' -type f 2>/dev/null)

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo ""
echo "Errors: $ERRORS | Warnings: $WARNS"
if [[ $ERRORS -gt 0 ]]; then
    echo "FAILED: $ERRORS documentation error(s) found."
    exit 1
else
    echo "PASSED: All documentation checks passed."
    exit 0
fi
