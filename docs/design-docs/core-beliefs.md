# Core Beliefs

## 1. The browser is the operating system
We use browser APIs as our kernel -- OPFS for filesystem, Web Workers for processes, SharedArrayBuffer for IPC, JSPI for async syscalls, File System Access API for host integration. We don't fight the browser; we build on it.

## 2. The browser is the window manager
We do not build custom window tiling, tabbing, or docking. Users open browser tabs and windows. Web Locks coordinate ownership. This eliminates thousands of lines of code and gives users the window management they already know.

## 3. Layers over monoliths
Persistence uses overlay layers like Docker: a read-only base rootfs + stackable package layers (Python, Node) + a writable user session delta. Only deltas are persisted. This keeps I/O small and boot fast.

## 4. Smaller base images are better
Every byte in the base rootfs costs us at download, at boot (tar parse + write to emulated FS), and at every delta computation. Strip the base to essentials. Packages go in layers.

## 5. Feature-detect, don't require
Every browser API integration must feature-detect and gracefully degrade. The app must work in a basic Chromium without any of the fancy APIs. They are progressive enhancements.

## 6. One write path
Persistence has exactly one write path. Redundant OPFS writes are a bug, not a feature. This was learned the hard way (see SESSION_LOG.md -- triple-write disaster).

## 7. Real tests, not theater
No mocked, faked, or simulated implementations. Tests verify observable behavior against the actual running emulator. If it's hard to test, the architecture needs to change, not the test.
