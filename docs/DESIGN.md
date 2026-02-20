# Design Philosophy

## Principles

1. **Userland emulation, not full-system.** AEON runs Linux binaries by emulating RISC-V user-mode instructions and intercepting syscalls. There is no kernel boot, no BIOS, no device model. This keeps the Wasm binary at ~500KB and startup fast.

2. **RISC-V over x86.** RISC-V's fixed-width, regular encoding maps cleanly to Wasm. The AOT/JIT compiler (rv2wasm) translates basic blocks 1:1 without the decoding complexity of variable-length x86.

3. **libriscv as the interpreter.** We use libriscv for the interpret loop and memory model, adding our own syscall layer, VFS, dynamic linker, and network stack on top.

4. **JSPI over Asyncify.** VectorHeart uses JSPI (`-sJSPI=1`) for async browser API calls. Asyncify instruments every function with save/restore code, bloating binaries 50-100%. JSPI suspends the Wasm stack natively. Only three functions are JSPI-suspended; everything else is sync fast-path.

5. **Docker as the input format.** Users provide a Docker image. It gets cross-compiled to RISC-V, rootfs extracted as tar, bundled with the Wasm runtime.

6. **Overlay layers for persistence.** Read-only base rootfs + stackable package layers + writable user delta. Only the delta persists. Inspired by Docker's overlay2.

7. **Browser as window manager.** No custom tiling/tabbing. Browser tabs = windows. Web Locks coordinate.

8. **Freehold for public DNS.** Each machine gets a publicly reachable domain via freehold tunnel.

## Architecture Decision Records

See [design-docs/index.md](design-docs/index.md) for the full ADR log.

## Related

- [../ARCHITECTURE.md](../ARCHITECTURE.md) -- system design and component map
- [RELIABILITY.md](RELIABILITY.md) -- syscall coverage guarantees
- [SECURITY.md](SECURITY.md) -- sandbox model
- [design-docs/core-beliefs.md](design-docs/core-beliefs.md) -- core beliefs
