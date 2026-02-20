# Main Agent Work Tracker

Primary agent (Claude Opus) progress tracker. Subagent tasks are in `work-tasks.md`.

## Completed

- [x] **Stego banner** — `aeon.jpg` + `aeon_stego.png` committed and pushed.
- [x] **Phase 1A: Kill triple-write** — Worker only sends tar via postMessage. Main thread saves delta via overlay.js. Single write path.
- [x] **Phase 1B: Wire overlay restore into boot** — baseTar copy kept (.slice()), overlay delta loaded and applied on boot, session created, worker OPFS restore removed.
- [x] **Phase 1C: Delta persistence** — computeDelta/applyDelta wired into handleWorkerMessage and boot. Deltas are JSON-encoded {added, modified, deleted}.
- [x] **Phase 1D: Add mergeTars()** — Tar union function added to overlay.js. Overlay entries win.
- [x] **Phase 1E: Package layer plumbing** — PackageManager.ts created, manifest.json created, boot path applies layers before session delta.
- [x] **Phase 2A: Web Locks** — boot() wrapped in navigator.locks.request(). Steal mode supported. Lock held via never-resolving promise.

## Remaining (primary owns)

- [ ] **Phase 2A-bis: Freehold integration** — Wire maceip/freehold client for public DNS per machine (deferred — needs research)
- [ ] **Phase 3A: FileSystemObserver** — Watch mounted local folders for changes (deferred)
- [ ] **Phase 3C: Document PiP** — Terminal pop-out via PiP API (deferred — complex)
- [ ] **Run tests** — `npx vitest run` to verify nothing broke
- [ ] **Build verification** — `npx vite build` to verify production build works
