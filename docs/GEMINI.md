# AEON (friscy) - Fast RISC-V Runtime for the Browser

AEON is a high-performance RISC-V 64-bit userland emulator that runs Docker containers directly in WebAssembly. It achieves native-like speeds by JIT-compiling RISC-V code regions into WebAssembly at runtime.

## Project Overview

- **Core Technology**: RISC-V 64-bit emulation via `libriscv`.
- **Primary Goal**: Run complex Linux environments (like Alpine Linux with Node.js/Claude Code) in a browser.
- **Architecture**:
  - **Runtime (C++)**: `libriscv` core + ~84 Linux syscall handlers + Tar-backed VFS + ELF loader.
  - **JIT/AOT (Rust)**: `rv2wasm` compiler that translates RISC-V instructions to Wasm.
  - **Frontend (TS/React)**: `xterm.js` terminal, SharedArrayBuffer-based I/O, and Web Workers.
  - **Networking**: WebTransport bridge to a Go-based TCP proxy.

## Key Directories

- `runtime/`: C++ source for the emulator and syscall emulation.
- `aot/`: Rust source for the `rv2wasm` AOT compiler.
- `aot-jit/`: Rust source for the JIT tier (compiled to wasm32).
- `friscy-bundle/`: Main browser deployment artifacts (HTML, JS, Worker, Wasm).
- `src/`: Modern React-based UI source code.
- `proxy/`: Go-based network proxy for WebTransport-to-TCP bridging.
- `sync-server/`: Node.js server for state synchronization.
- `docs/`: Comprehensive documentation (Architecture, Workstreams, Roadmap).
- `tests/`: Integration and unit tests for various components.

## Building and Running

### Development Server
To run the browser-based terminal:
```bash
node friscy-bundle/serve.js 9000
```
Then open `https://localhost:9000` (Chrome recommended for COOP/COEP and SAB support).

### Building the Runtime (Emscripten)
Requires Docker and `emsdk`.
```bash
bash tools/harness.sh
```
This syncs `friscy.{js,wasm}` to `friscy-bundle/`.

### Building Native Runtime
```bash
mkdir build && cd build
cmake ../runtime
make -j$(nproc)
./friscy --rootfs ../friscy-bundle/rootfs.tar /bin/sh
```

### Building the AOT/JIT Compiler
```bash
cd aot && cargo build --release
# To build the JIT for the browser:
cd aot-jit && wasm-pack build --target web
```

## Development Conventions

- **Memory Model**: Uses a 31-bit (2GB) flat arena for O(1) memory access within a 4GB wasm32 address space.
- **I/O Boundary**: All I/O between the emulator (Web Worker) and the UI (Main Thread) occurs via `SharedArrayBuffer` using `Atomics.wait/notify`.
- **Syscall Implementation**: New syscalls should be added to `runtime/syscalls.hpp`. Follow the "Architecture Invariants" in `ARCHITECTURE.md`.
- **Testing**: Use `vitest` for frontend tests and the scripts in `tests/` for runtime/integration tests.
- **Styling**: Tailwind CSS is used for the React frontend.
