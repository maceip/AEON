# AEON Session Log - 2026-02-19

## Setup

Forked `friscy` into `AEON` (same parent directory) using `git archive HEAD` to export only git-tracked files. Removed all `.tar` and `.wasm` binary assets. Initialized fresh git repo with baseline commit.

---

## Full Code Review & Bug Fixes

Systematically read every source file in `src/`:
- App.tsx, main.tsx, DesktopLayout.tsx, WindowFrame.tsx, TerminalView.tsx
- AppShelf3D.tsx, IntroOverlay.tsx, FuturisticNotepad.tsx, GitArkanoid.tsx
- SupportingView.tsx, SortableTab.tsx, WaveformVisualizer.tsx, ProgressOverlay.tsx
- FriscyMachine.ts, emulator.worker.ts, emulator.ts (types)
- useASR.ts, ThemeContext.tsx, index.css, vite.config.ts

### Bugs Found & Fixed

| Severity | File | Issue | Fix |
|----------|------|-------|-----|
| P0 | `DesktopLayout.tsx` | Stray `import` statements on lines 85-87 inside JSX return block - completely broken syntax | Removed stray lines, added proper import at top of file |
| P0 | `DesktopLayout.tsx` | Missing `SupportingView` import | Added `import { SupportingView } from './SupportingView'` |
| P1 | `SupportingView.tsx` | Global `Ctrl+C` listener hijacks system clipboard everywhere | Removed the listener entirely, left TODO for non-conflicting trigger |
| P1 | `FuturisticNotepad.tsx` | `alert()` call blocks browser event loop | Replaced with inline toast notification that auto-dismisses after 3s |
| P2 | `SupportingView.tsx` | External dependency on `transparenttextures.com` for jedi door texture | Replaced with CSS-only repeating-linear-gradient grid pattern |
| P2 | `AppShelf3D.tsx` | Broken font path `/fonts/maple-mono.woff` (file doesn't exist) | Pointed to CDN URL that index.css already references |
| P2 | `App.tsx` | 4 unused imports (`WaveformVisualizer`, `Sun`, `Moon`, `X`) | Removed, kept only `Plus` which is used |
| P2 | `index.css` | Duplicate `@layer base` block overriding the one with scanlines background | Removed duplicate block |
| P2 | `vite.config.ts` | Build fails - workbox precache limit too low for 2.87MB bundled chunk (Three.js + onnxruntime) | Added `maximumFileSizeToCacheInBytes: 5 * 1024 * 1024` |
| P2 | `ProgressOverlay.test.tsx` | Test searches for 'friscy' but rendered text is 'fRISCy' | Fixed to match actual casing |
| P2 | `App.test.tsx` | Missing ResizeObserver mock, expects 'Gemini Agent' window title that doesn't exist | Added mock, corrected to actual titles: 'Claude Code', 'System Config', 'App Hub' |
| P2 | `package.json` | Missing `@testing-library/dom` dev dependency | Installed it |

### Final State
- `npx tsc --noEmit` - clean, no errors
- `npx vite build` - succeeds (23s, 2595 modules)
- `npx vitest run` - 13/13 tests pass across 4 suites
- Committed as `ac6eccc`

---

## Status of What's Solid vs Placeholder

### Working:
- Core emulator pipeline (FriscyMachine -> Worker -> SharedArrayBuffer 4ms polling)
- Terminal (xterm.js + WebGL addon + drag-drop file decompression + ASR)
- Window management (dnd-kit sortable, minimize/maximize/popout)
- Boot sequence with jedi door open animation
- AppShelf3D 3D carousel with custom shader
- Notepad with markdown preview + localStorage persistence
- Theme system (dark/light with localStorage)
- Progress overlay (squiggly canvas animation)
- OPFS persistence (basic - worker writes/restores full VFS tar)

### Placeholder / Not Wired:
- Git Arkanoid - static mock data, "Rebase Origin" button does nothing
- Clipboard hub - was Ctrl+C activated, now disabled
- Environment matrix - static display only
- Supportive agent interface - doesn't exist in AEON (HolographicMachine wasn't committed)

---

## OPFS / Overlay System Analysis

**Q: Does the OPFS filesystem stuff work?**

Two separate persistence paths exist:

1. **Worker direct OPFS** (works): `emulator.worker.ts` writes `persisted_rootfs.tar` to OPFS root on every VFS export, restores it on next boot. FriscyMachine triggers this every 10 seconds via `CMD_EXPORT_VFS`.

2. **overlay.js session system** (dead code): Full session management (`createSession`, `listSessions`, `deleteSession`), delta compression (`computeDelta`, `applyDelta`), auto-save timer - none of it is called from anywhere. `FriscyMachine.ts` imports `loadOverlay`, calls it on boot, logs the size, then throws the result away.

The two systems don't talk to each other. Persistence works via path #1 only.

**Q: What is an overlay?**

Linux filesystem concept from containers (Docker overlay2). A read-only **base layer** (original rootfs) plus a writable **overlay layer** on top that captures only changes. The OS sees a merged view. Benefits: only need to persist the diff (KB/MB) instead of the full filesystem (100MB+). The `computeDelta`/`applyDelta` in overlay.js implement this in JS but are never used - the worker just dumps the entire VFS tar every time.

---

## What Needs Doing Next

1. **Supportive agent interface** (top priority per user) - needs to be genuinely useful, not sycophantic
2. Terminal tabs (tab bar code exists but not fully integrated)
3. Wire up overlay.js session system or remove it
4. Copy-paste hub with non-destructive trigger
5. Wire git visualizer to real data
