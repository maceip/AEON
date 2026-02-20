# Product Sense

## Who is AEON for?

**Primary user:** Developers, designers, and builders who want a fast, sandboxed Linux environment in the browser for building software, running CLI tools, and managing multiple terminal sessions.

**Jobs to be done:**

1. Open a browser tab and have a Linux terminal ready in seconds -- no VM, no Docker install, no server.
2. Run real developer tools: Claude Code, Gemini CLI, Python, Node.js, Go -- in isolated sandboxed environments.
3. Mount a local project folder into the emulated Linux and work with it using CLI tools.
4. Share a running environment via a public URL (freehold DNS) so a teammate or user can interact with it from any device.
5. Snap on language runtimes (Python, Node) as overlay layers without rebuilding the base image.
6. Open multiple browser tabs/windows to work with different views of the same running machine.

## Product Principles

1. **Browser-native.** The browser IS the platform. We use its APIs as our kernel, its tabs as our window manager, its storage as our filesystem.
2. **Instant-on.** Boot time matters more than peak throughput. A smaller base image and overlay layers mean the terminal is ready fast.
3. **Real tools, not toys.** Users run real CLIs (Claude Code, git, curl, python). If a tool doesn't work, that's a bug.
4. **Multiplexed by default.** Multiple terminals, multiple tabs, one machine. Like tmux but the browser is the multiplexer.
5. **Publicly addressable.** Every machine gets a freehold DNS name. A Go server running inside the emulator is reachable from the internet.

## Competitive Positioning

| Feature | WebVM | container2wasm | v86 | **AEON** |
|---------|-------|----------------|-----|----------|
| ISA | x86 (JIT) | x86 (Bochs) | x86 (JIT) | RISC-V (interp+JIT) |
| Boot time | 3-5s | 30-60s | 5-10s | <2s |
| Kernel | Yes | Yes | Yes | No (userland) |
| Persistence | Limited | No | No | OPFS overlay layers |
| Local folder mount | No | No | No | Yes (File System Access) |
| Public DNS | No | No | No | Yes (freehold) |
| Package layers | No | No | No | Yes (snap-on tars) |

## Non-goals

- Full Linux kernel emulation (no device drivers, no kernel modules).
- GUI / desktop environment support (terminal-first).
- Competing with cloud VM providers for production workloads.
- Mobile-first (desktop Chrome is the primary target; mobile is progressive).
