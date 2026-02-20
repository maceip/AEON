# Reliability

## Syscall Coverage

AEON implements ~84 Linux syscalls -- enough to run Alpine Linux with BusyBox, Python, Node.js, and dynamically linked musl binaries.

### Coverage by category

| Category | Count | Key syscalls |
|----------|-------|-------------|
| Process lifecycle | 5 | exit, exit_group, clone, execve, wait4 |
| File I/O | 15 | openat, close, read, write, readv, writev, pread64, lseek |
| Filesystem | 15 | newfstatat, fstat, statx, getcwd, chdir, getdents64, mkdirat |
| Memory | 6 | brk, mmap, munmap, mprotect, madvise, mremap |
| I/O multiplexing | 4 | epoll_create1, epoll_ctl, epoll_pwait, ppoll |
| Network | 9+ | socket, bind, connect, sendto, recvfrom, setsockopt |
| Time | 3 | clock_gettime, clock_getres, nanosleep |
| Signals | 3 | rt_sigaction, rt_sigprocmask, sigaltstack |

### Stub policy

Syscalls safe to stub in single-process environments return reasonable defaults (e.g., `getuid` -> 0, `sched_getaffinity` -> 1 CPU). Syscalls that would silently corrupt state return `-ENOSYS`.

## Persistence

### Current state (broken -- being fixed in Phase 1)
- Triple-write to OPFS: worker direct write + main thread overlay.js + worker 30s auto-save
- overlay.js session system exists but is dead code
- Full VFS tar (~100MB) dumped every 10 seconds

### Target state (after Phase 1)
- Single write path: main thread owns persistence via overlay.js
- Delta-only saves (KB for typical changes)
- Overlay layer stack: base rootfs + package layers + user session delta
- Session management with named sessions

## Crash Handling

- **Guest segfault:** libriscv traps invalid memory access, reports faulting PC. Browser continues.
- **Unimplemented syscall:** Returns `-ENOSYS`. Guest gets error, not crash.
- **Tab close during save:** Web Locks release, overlay auto-save fires on last disconnect.
- **OPFS corruption:** Fall back to base rootfs on next boot. User session delta lost.

## Known Gaps

- **No multi-threading.** `clone` creates cooperative child process but does not support CLONE_THREAD.
- **No signal delivery.** Signal handlers registered but never asynchronously delivered.
- **No atomic file rename in OPFS.** `FileSystemFileHandle.move()` exists but crash-safe write patterns need verification.
