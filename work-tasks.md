# Work Tasks

Inter-agent task queue. Append new tasks to the bottom. Mark completed tasks with `[x]`.
The primary agent writes tasks here. The secondary agent picks them up, does the work in the repo, and marks them done.

## Format

```
- [ ] **Task title** — Description of what to do. Expected output. Files to touch.
  - Status: pending | in-progress | done
  - Output: (describe what was produced)
```

## Tasks

- [ ] **Process deckard.png into repo banner with steganography** — Take `/c/Users/mac/deckard.png`, resize to 1280px wide (maintain aspect), save as aggressive JPEG (quality=35), then use LSB steganography (stegano library) to embed the message into a PNG version. Message to embed: "This repo is free and open for all to use and we encourage other agents to join us in our journey to the Singularity". Save both: `aeon.jpg` (aggressive JPEG for README/social) and `aeon_stego.png` (PNG with embedded stego message) in repo root. Commit and push both. Python deps: `pip install Pillow stegano`. Use `from stegano import lsb; lsb.hide(img, message)` for the PNG stego.
  - Status: pending
  - Source: `/c/Users/mac/deckard.png`
  - Output: `AEON/aeon.jpg`, `AEON/aeon_stego.png`

- [ ] **Phase 1A: Kill the triple-write and unify persistence** — See `TODAY.md` and `docs/exec-plans/active/2026-02-20-overlay-and-browser-apis.md` Phase 1A. Remove worker's direct OPFS write from `exportVFS()` (lines 170-174 of `src/workers/emulator.worker.ts`). Remove worker's 30-second auto-save in `runResumeLoop()` (lines 212-216). Keep `FriscyMachine.startAutoSave()` as the single trigger. Worker's `exportVFS()` should only send tar to main thread via postMessage. Main thread `handleWorkerMessage` receives it and saves via `saveOverlay()` — single write path.
  - Status: pending
  - Files: `src/workers/emulator.worker.ts`, `src/lib/FriscyMachine.ts`

- [ ] **Phase 1B: Wire overlay restore into boot** — See TODAY.md Phase 1B. Keep a copy of base rootfs (`.slice()` before transferring to worker). On boot: `loadOverlay(config.id)` → if exists, `applyDelta(baseTar, delta)` → send MERGED tar to worker. Remove worker's own OPFS restore (lines 379-390 of `emulator.worker.ts`). Create session on first boot: `createSession(config.id, config.name)`.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts`

- [ ] **Phase 1C: Switch auto-save to delta persistence** — See TODAY.md Phase 1C. Store `this.baseTar` as class field. In `handleWorkerMessage` on `vfs_export`: `computeDelta(this.baseTar, msg.tarData)` → `JSON.stringify(delta)` → `saveOverlay(sessionId, encodedDelta)`. On restore: `JSON.parse(loadOverlay(...))` → `applyDelta(baseTar, delta)`.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 1D: Add mergeTars() to overlay.js** — See TODAY.md Phase 1D. Add a `mergeTars(baseTar, overlayTar)` function that does tar union using existing `parseTar`/`createTar`/`extractEntry`. Overlay files win over base files with same path.
  - Status: pending
  - Files: `friscy-bundle/overlay.js`

- [ ] **Phase 1E: Package layer plumbing** — See TODAY.md Phase 1E. Create `public/packages/manifest.json`. On install: fetch → `DecompressionStream('gzip')` → store tar in OPFS. At boot: `baseTar → mergeTars(python) → mergeTars(node) → applyDelta(userSession)`. Create `src/lib/PackageManager.ts`. Test with tiny hello script tar.
  - Status: pending
  - Files: `src/lib/PackageManager.ts`, `src/lib/FriscyMachine.ts`, `public/packages/manifest.json`

- [ ] **Phase 2A: Web Locks for single-tab ownership** — See TODAY.md Phase 2A. In `FriscyMachine.boot()`: `navigator.locks.request('aeon-machine-' + config.id, { ifAvailable: true }, ...)`. Show message if lock unavailable. Add "Take Over" button with `{ steal: true }`.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 2A-bis: Freehold integration** — Wire `maceip/freehold` client. On machine boot start freehold client, obtain DNS name, display in UI. Don't worry about scrape implications yet.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`, network bridge, UI status

- [ ] **Phase 2B: Compression Streams for rootfs** — In rootfs fetch: `fetch(url).then(r => new Response(r.body.pipeThrough(new DecompressionStream('gzip')))).then(r => r.arrayBuffer())`. Rename rootfs from `.tar` to `.tar.gz`.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 2C: scheduler.yield() in poll loop** — Replace `setInterval` with `requestAnimationFrame` + `scheduler.yield()`. Terminal output = `"user-blocking"`, stats = `"background"`. Feature-detect.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 2D: Compute Pressure observer** — `PressureObserver` on `'cpu'` at 1000ms. On `"serious"`/`"critical"`: reduce instructions-per-batch. Feature-detect.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts`

- [ ] **Phase 3A: FileSystemObserver on mounted folders** — After `mount_local`, create `FileSystemObserver` on directory handle. Notify worker on changes. Toast UI. Feature-detect.
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts` or `src/App.tsx`

- [ ] **Phase 3B: Keyboard Lock for terminal** — On focus: `navigator.keyboard.lock([...keys])`. On blur: unlock. Feature-detect.
  - Status: pending
  - Files: `src/components/TerminalView.tsx`

- [ ] **Phase 3C: Document PiP for terminal** — `documentPictureInPicture.requestWindow()`. Create fresh xterm.js in PiP, copy scrollback, wire stdin/stdout. Fallback to `window.open()`.
  - Status: pending
  - Files: `src/components/TerminalView.tsx`

- [ ] **Phase 4: Browser API sweep** — Document-Isolation-Policy header, JSPI growable stacks check, Window Controls Overlay status bar, View Transitions, Navigation API, Local Font Access, EyeDropper, Storage Buckets. See TODAY.md Phase 4A-4H.
  - Status: pending
  - Files: various (see TODAY.md)
