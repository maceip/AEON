# Work Tasks

Inter-agent task queue. Primary agent (Claude Opus) owns heavy-lift items. Secondary agent picks up assigned tasks.

## Format

```
- [ ] **Task title** — Description. Files to touch.
  - Owner: primary | subagent
  - Status: pending | in-progress | done
  - Output: (describe what was produced)
```

## Completed

- [x] **Process deckard.png into repo banner with steganography** — Committed and pushed `aeon.jpg` + `aeon_stego.png`.
  - Owner: primary
  - Status: done
  - Output: `aeon.jpg` (1280x1028, JPEG q=35), `aeon_stego.png` (LSB stego verified)

- [x] **Phase 1A (worker side): Remove redundant OPFS writes** — Removed worker's direct OPFS write from `exportVFS()` and 30s auto-save from `runResumeLoop()`. Worker now only sends tar to main via postMessage.
  - Owner: primary
  - Status: done
  - Output: Committed and pushed `b5aa6d9`

## In Progress — Primary Agent (DO NOT TOUCH)

- [ ] **Phase 1A (main thread side): Wire saveOverlay as single write path** — In `FriscyMachine.ts`, ensure `handleWorkerMessage` on `vfs_export` calls `saveOverlay()` from `overlay.js` instead of any direct OPFS write. This completes the single-write-path unification.
  - Owner: primary
  - Status: in-progress
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 1B: Wire overlay restore into boot** — Keep a copy of base rootfs (`.slice()` before transfer). On boot: `loadOverlay()` → if exists, `applyDelta(baseTar, delta)` → send MERGED tar to worker. Remove worker's OPFS restore. Create session on first boot.
  - Owner: primary
  - Status: pending (blocked on 1A completion)
  - Files: `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts`

- [ ] **Phase 1C: Switch auto-save to delta persistence** — Store `this.baseTar` as class field. `handleWorkerMessage` on `vfs_export`: `computeDelta(this.baseTar, msg.tarData)` → save delta. On restore: `applyDelta(baseTar, delta)`.
  - Owner: primary
  - Status: pending (blocked on 1B)
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 1E: Package layer plumbing** — Create `PackageManager.ts`, boot-time layer stack, `public/packages/manifest.json`.
  - Owner: primary
  - Status: pending (blocked on 1D)
  - Files: `src/lib/PackageManager.ts`, `src/lib/FriscyMachine.ts`, `public/packages/manifest.json`

- [ ] **Phase 2A: Web Locks for single-tab ownership** — `navigator.locks.request()` in boot, "Take Over" button with `{ steal: true }`.
  - Owner: primary
  - Status: pending (after Phase 1)
  - Files: `src/lib/FriscyMachine.ts`

## Assigned to Subagent

These tasks are independent, self-contained, and safe for the subagent. Do them in order.

- [ ] **Phase 1D: Add mergeTars() to overlay.js** — Add a `mergeTars(baseTar, overlayTar)` function to `friscy-bundle/overlay.js`. It does tar union: parse both tars with existing `parseTar`, overlay files win over base files with the same path, produce a new tar with `createTar`. Use the existing `extractEntry` to get file contents. The function signature is `export function mergeTars(baseTar, overlayTar)` where both args are ArrayBuffers. Return an ArrayBuffer. Add it right after the `applyDelta` function. Also export it from the module.
  - Owner: subagent
  - Status: pending
  - Files: `friscy-bundle/overlay.js`
  - Acceptance: function exists, exported, handles empty overlay gracefully

- [ ] **Phase 2B: Compression Streams for rootfs loading** — In `src/lib/FriscyMachine.ts`, find the rootfs fetch path and wrap it with DecompressionStream. The pattern: `fetch(url).then(r => new Response(r.body.pipeThrough(new DecompressionStream('gzip')))).then(r => r.arrayBuffer())`. Feature-detect `DecompressionStream` and fall back to raw fetch. Add a comment noting rootfs files should be served as `.tar.gz` once the server is updated.
  - Owner: subagent
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 2C: scheduler.yield() in poll loop** — In `src/lib/FriscyMachine.ts`, find the `setInterval` poll loop and replace it with `requestAnimationFrame` + `scheduler.yield()`. Terminal output draining = `"user-blocking"`, stats = `"background"`. Feature-detect: `if ('scheduler' in globalThis && 'yield' in scheduler)`, fall back to existing setInterval.
  - Owner: subagent
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`

- [ ] **Phase 2D: Compute Pressure observer** — Add `PressureObserver` watching `'cpu'` at 1000ms sample interval to `src/lib/FriscyMachine.ts`. On `"serious"` or `"critical"`: post message to worker to halve instructions-per-batch. On `"nominal"`: restore full speed. Feature-detect: `if ('PressureObserver' in globalThis)`. Worker side: in `src/workers/emulator.worker.ts`, accept a `throttle` message that adjusts the batch size variable.
  - Owner: subagent
  - Status: pending
  - Files: `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts`

- [ ] **Phase 3B: Keyboard Lock for terminal** — In `src/components/TerminalView.tsx`, when the terminal container gets focus, call `navigator.keyboard.lock(['Escape','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12'])`. On blur, call `navigator.keyboard.unlock()`. Feature-detect: `if ('keyboard' in navigator && 'lock' in navigator.keyboard)`.
  - Owner: subagent
  - Status: pending
  - Files: `src/components/TerminalView.tsx`

- [ ] **Phase 4A: Document-Isolation-Policy header** — Add `<meta http-equiv="Document-Isolation-Policy" content="isolate-and-require-corp">` to `index.html` (or the vite config headers). This may allow SharedArrayBuffer without COOP/COEP.
  - Owner: subagent
  - Status: pending
  - Files: `index.html` or `vite.config.ts`

- [ ] **Phase 4H: Storage Buckets for isolated persistence** — In `friscy-bundle/overlay.js`, replace the default `navigator.storage.getDirectory()` calls with Storage Buckets: `await navigator.storageBuckets.open('aeon-rootfs', { persisted: true, durability: 'strict' })` then use `bucket.getDirectory()`. Feature-detect: `if ('storageBuckets' in navigator)`, fall back to default OPFS root.
  - Owner: subagent
  - Status: pending
  - Files: `friscy-bundle/overlay.js`

## Deferred (not today)

- Phase 2A-bis: Freehold integration (needs more research on maceip/freehold client API)
- Phase 3A: FileSystemObserver (Chrome 133+, nice-to-have)
- Phase 3C: Document PiP for terminal (complex xterm.js migration)
- Phase 4B-4G: Window Controls Overlay, View Transitions, Navigation API, Local Font Access, EyeDropper (polish)
