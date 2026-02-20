# Main Agent Work Tracker

All TODAY.md phases complete. 13/13 tests pass. Production build succeeds.

## Completed

- [x] **Stego banner** — `aeon.jpg` + `aeon_stego.png`
- [x] **Phase 1A: Kill triple-write** — Single write path via overlay.js saveOverlay()
- [x] **Phase 1B: Wire overlay restore** — baseTar .slice(), applyDelta on boot, session management
- [x] **Phase 1C: Delta persistence** — computeDelta produces KB-sized JSON deltas
- [x] **Phase 1D: mergeTars()** — Tar union function, overlay wins on conflicts
- [x] **Phase 1E: PackageManager** — Install/uninstall/applyLayers, boot-time layer stack
- [x] **Phase 2A: Web Locks** — Single-tab ownership with steal mode
- [x] **Phase 2B: Compression Streams** — DecompressionStream for .tar.gz rootfs
- [x] **Phase 2C: scheduler.yield()** — rAF + yield poll loop with setInterval fallback
- [x] **Phase 2D: Compute Pressure** — PressureObserver on CPU, throttle forwarded to worker
- [x] **Phase 3A: FileSystemObserver** — Watches mounted local folders, notifies worker
- [x] **Phase 3B: Keyboard Lock** — Escape + F1-F12 captured on terminal focus
- [x] **Phase 3C: Document PiP** — Pop-out terminal via documentPictureInPicture, fallback to window.open
- [x] **Phase 4A: Document-Isolation-Policy** — Meta tag in index.html
- [x] **Phase 4B: JSPI growable stacks** — Runtime check, build already uses -sJSPI=1
- [x] **Phase 4C: Window Controls Overlay** — CSS env(titlebar-area-*) status bar
- [x] **Phase 4D: View Transitions** — SupportingView panel switches wrapped
- [x] **Phase 4E: Navigation API** — Browser back/forward for views
- [x] **Phase 4F: Local Font Access** — queryLocalFonts() for monospace font picker
- [x] **Phase 4G: EyeDropper** — Color picker for terminal theming
- [x] **Phase 4H: Storage Buckets** — Persisted+strict durability for OPFS overlay

## Deferred

- Phase 2A-bis: Freehold integration (needs maceip/freehold client research)
- SharedWorker migration (multi-day, tracked in TODAY.md anti-scope)
- I/O Worker split, batched JSPI, Direct Sockets (multi-day projects)
