# Plans & Roadmap

See `docs/exec-plans/active/` for detailed execution plans.
See `TODAY.md` for the current day's implementation priorities.

## Current Focus (2026-02-20)

### Phase 1: Overlay System
Wire up the existing overlay.js code that is currently dead. Kill the triple-write persistence mess. Switch to delta-only saves. Add tar merge for package layers.

### Phase 2: Performance & Multi-Tab
Web Locks for single-tab ownership. Compression Streams for rootfs loading. scheduler.yield() for responsive UI. Compute Pressure for adaptive throttling. Freehold integration for public DNS.

### Phase 3: File System UX
FileSystemObserver on mounted local folders. Keyboard Lock for terminal. Document Picture-in-Picture for pop-out.

### Phase 4: Browser API Sweep
Document-Isolation-Policy. JSPI growable stacks verification. Window Controls Overlay. View Transitions. Navigation API. Local Font Access. EyeDropper. Storage Buckets.

## Near-term

- [ ] Overlay persistence with delta compression (Phase 1)
- [ ] Package layer system (Python, Node snap-on tars)
- [ ] Freehold integration (public DNS per machine)
- [ ] SharedWorker migration for true multi-tab shared machine
- [ ] Full browser API integration sweep

## Medium-term

- [ ] Research WASM Tail Calls for interpreter dispatch
- [ ] Research WASM Multi-Memory for guest RAM vs emulator internals
- [ ] Batched JSPI / io_uring-style async I/O
- [ ] Dedicated I/O Worker (separate from CPU Worker)

## Long-term

- [ ] WASM Stack Switching for coroutine-style emulation (when Chrome ships it)
- [ ] WASM Memory64 for >4GB emulated RAM
- [ ] Direct Sockets via Isolated Web App packaging
- [ ] WebGPU compute for framebuffer rendering

## See Also

- [exec-plans/active/](exec-plans/active/) -- detailed plans for in-flight work.
- [exec-plans/completed/](exec-plans/completed/) -- archived plans.
- [exec-plans/tech-debt-tracker.md](exec-plans/tech-debt-tracker.md) -- known debt.
