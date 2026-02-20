<div align="center">
<table border="0" style="border-collapse: collapse; border-style: hidden;">
  <tr>
    <td align="left" valign="bottom" style="border: none; padding-right: 30px;">
<pre>
 ▄▀▄ ▄▀▀ ▄▀▄ ▄▀▄
 █▀█ █▀▀ █ █ █ █
 ▀ ▀ ▀▀▀ ▀▀▀ ▀ ▀
</pre>
      <br>
      <strong>AEON — Linux in the browser, no servers required</strong>
      <br><br>
      <ul align="left" style="margin-top: 0;">
        <li>Run Docker containers in a RISC-V emulator compiled to WebAssembly</li>
        <li>JIT-compile hot code regions to native Wasm at runtime</li>
        <li>Native checkpoint/restore for instant resume (skips boot)</li>
        <li>OPFS overlay persistence with delta compression</li>
        <li>Interactive terminal with xterm.js + TCP networking</li>
      </ul>
    </td>
    <td valign="bottom" style="border: none;">
      <img width="238" height="313" alt="aeon" src="docs/assets/aeon.jpg" />
    </td>
  </tr>
</table>
</div>

<p align="center">
  <a href="https://maceip.github.io/AEON/"><strong>Live Demo</strong></a>
</p>
<br>

## Milestone: Claude Code in the Browser

AEON boots Claude Code (`@anthropic-ai/claude-code` 2.1.39) inside a RISC-V
emulator running in WebAssembly. The guest environment is Alpine Linux (edge, riscv64)
with Node.js 24 running in `--jitless` mode. With checkpoint restore, the full
environment resumes instantly from a pre-built snapshot.

```
claude --version  →  2.1.39 (Claude Code)    # 3.4 billion RISC-V instructions
```

## Project Status

| Component | Status | Notes |
|-----------|--------|-------|
| Interpreter (libriscv) | Complete | RV64GC, threaded dispatch, ~40% native speed |
| Syscall Emulation | Complete | ~80 syscalls: file, process, network, memory, signals, epoll |
| Virtual Filesystem | Complete | Tar-backed, read-write, symlinks, /proc, /dev emulation |
| Dynamic Linker | Complete | ld-musl, aux vector, execve with interpreter reload |
| Networking | Complete | TCP via WebTransport proxy, epoll, accept4 |
| AOT Compiler (rv2wasm) | Complete | RISC-V → Wasm, FP, br_table dispatch |
| JIT Tier | Complete | rv2wasm compiled to wasm32, runtime hot-region compilation |
| Worker + SAB | Complete | Emulator in Web Worker, Atomics.wait/notify I/O |
| Checkpoint/Restore | Complete | Binary machine state serialization, instant resume |
| Overlay Persistence | Complete | OPFS delta compression, package layers, Storage Buckets |
| Browser API Integration | Complete | Web Locks, Compression Streams, Compute Pressure, PiP, Keyboard Lock |
| Web Shell | Complete | xterm.js, clipboard, terminal resize, voice input, progress UI |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Browser (Main Thread)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  xterm.js    │  │ network_rpc  │  │  jit_manager.js          │  │
│  │  terminal    │  │ _host.js     │  │  (hot region detection)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────────────────┘  │
│         │ stdin/stdout     │ WebTransport                            │
│         ▼                  ▼                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              SharedArrayBuffer (4KB + 64KB + 64KB)           │   │
│  │   control SAB │ stdout ring buffer │ network RPC buffer      │   │
│  └──────────────────────────┬──────────────────────────────────┘   │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ Atomics.wait / Atomics.notify
┌──────────────────────────────▼──────────────────────────────────────┐
│                        Web Worker                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    friscy.wasm (Emscripten)                   │    │
│  │  ┌─────────────────────────────────────────────────────┐    │    │
│  │  │              libriscv RV64GC Core                     │    │    │
│  │  │  • Threaded dispatch (computed goto → br_table)      │    │    │
│  │  │  • 2GB flat arena (31-bit, O(1) memory access)       │    │    │
│  │  │  • 1024 execute segments                             │    │    │
│  │  └─────────────────────────────────────────────────────┘    │    │
│  │  ┌─────────────────────────────────────────────────────┐    │    │
│  │  │  Syscall Layer (~80 syscalls)                        │    │    │
│  │  │  • syscalls.hpp: file, process, memory, signals      │    │    │
│  │  │  • network.hpp: socket, epoll, accept4               │    │    │
│  │  │  • vfs.hpp: tar-backed filesystem                    │    │    │
│  │  │  • elf_loader.hpp: dynamic linking, execve           │    │    │
│  │  └─────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  rv2wasm_jit.wasm (runtime JIT compiler)                     │    │
│  │  • Compiles hot RISC-V regions → native Wasm at runtime      │    │
│  │  • Shares WebAssembly.Memory with interpreter                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
AEON/
├── runtime/              # C++ emulator (libriscv + syscalls)
│   ├── CMakeLists.txt    # Emscripten + native build config
│   ├── main.cpp          # Entry point, simulate loop, checkpoint CLI
│   ├── syscalls.hpp      # ~80 Linux syscall handlers + clone3
│   ├── checkpoint.hpp    # Binary machine state serialization
│   ├── network.hpp       # Socket, epoll, accept4 handlers
│   ├── vfs.hpp           # Virtual filesystem (tar-backed)
│   └── elf_loader.hpp    # ELF loading, dynamic linker, execve
│
├── src/                  # React frontend (TypeScript + Vite)
│   ├── App.tsx           # Main app, presets, boot orchestration
│   ├── lib/
│   │   ├── FriscyMachine.ts   # Machine lifecycle, Web Locks, persistence
│   │   └── PackageManager.ts  # OPFS package layer management
│   ├── workers/
│   │   └── emulator.worker.ts # Web Worker (emulator loop, checkpoint)
│   ├── components/       # UI: terminal, window frame, overlays
│   ├── contexts/         # Theme context
│   ├── hooks/            # ASR hook
│   └── types/            # TypeScript types (emulator, worker messages)
│
├── aot/                  # rv2wasm AOT compiler (Rust)
├── aot-jit/              # JIT tier (rv2wasm → wasm32 via wasm-bindgen)
│
├── friscy-bundle/        # Browser deployment bundle
│   ├── worker.js         # Standalone Web Worker (non-Vite mode)
│   ├── overlay.js        # OPFS overlay: delta, sessions, tar utils
│   ├── jit_manager.js    # Hot-region detection, compile, dispatch
│   ├── friscy.js/wasm    # Emscripten module
│   ├── rv2wasm_jit*.wasm # JIT compiler
│   ├── rootfs.tar        # Container rootfs
│   └── claude-repl.ckpt  # Pre-built checkpoint for instant resume
│
├── scripts/              # Build & utility scripts
│   ├── claude-cli.js     # Claude Code CLI bundle
│   ├── serve-dist.js     # Production server with COOP/COEP
│   └── sign-bundle.js    # Bundle signing
│
├── docs/                 # Documentation, plans, research
│   ├── assets/           # Images (aeon.jpg, aeon_stego.png)
│   ├── exec-plans/       # Execution plans
│   ├── TODAY.md           # Daily implementation plan
│   └── *.md              # Research, demos, performance plans
│
├── tools/                # Docker build tools
├── proxy/                # WebTransport network proxy (Go)
├── sync-server/          # WebSocket state sync server
├── tests/                # Integration tests
├── vendor/libriscv/      # libriscv emulator library
├── AGENTS.md             # Agent instructions & invariants
├── ARCHITECTURE.md       # System design (matklad style)
└── README.md             # This file
```

## Quick Start

### Serve the Web Shell

```bash
node friscy-bundle/serve.js 9000
# Open https://localhost:9000 in Chrome
```

Requires COOP/COEP headers for SharedArrayBuffer (serve.js handles this).

### Build Emscripten (Reproducible)

```bash
# Uses pinned versions from tools/build-lock.env.
# Docker if available:
bash tools/harness.sh

# Force native emsdk (no Docker):
bash tools/harness.sh --native

# Sync built artifacts into browser bundle:
cp runtime/build/friscy.{js,wasm} friscy-bundle/
```

### Build Native

```bash
mkdir -p build-native && cd build-native
cmake ../runtime && make -j$(nproc)
./friscy --rootfs ../friscy-bundle/rootfs.tar /bin/sh
```

### Reproducible Build + Test

```bash
# Run claude --version smoke against checked-in stable bundle runtime
bash tools/build_and_test.sh

# Attempt runtime rebuild first, then smoke test (restores stable bundle on failure):
bash tools/build_and_test.sh --rebuild-runtime --native

# Include haiku attempt in the same run:
bash tools/build_and_test.sh --haiku

# Run synthetic Claude-like workload (large JS parse + streamed API response):
bash tools/build_and_test.sh --synthetic-stream --synthetic-bundle-mb 6

# Validate the local mock streaming API service directly:
node --experimental-default-type=module ./tests/test_mock_stream_service.js

# Sweep emsdk/libriscv compatibility for runtime rebuild debugging:
bash tools/runtime_compat_sweep.sh --emsdk 5.0.1 4.0.23 4.0.20

# Sweep across historical source refs (isolated worktrees) as well:
bash tools/runtime_source_ref_sweep.sh --source-ref HEAD bb8b6f1 1cc5c80 --emsdk 5.0.1 --libriscv 396f8c206515cbec404677bbce23a211d7959216

# Override workload/query under test (example: no-JIT version smoke):
bash tools/runtime_compat_sweep.sh --test-query '?noproxy&nojit=1'
```

### Build Claude Rootfs

```bash
docker buildx build --platform linux/riscv64 -f tools/Dockerfile.claude -t friscy-claude . --load
docker create --name tmp friscy-claude && docker export tmp > friscy-bundle/rootfs.tar && docker rm tmp
```

### Build AOT Compiler

```bash
cd aot && cargo build --release
./target/release/rv2wasm input.elf -o output.wasm
```

## Key Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Arena size | 31-bit (2GB) | Node.js/V8 needs ~1.15GB for pointer cage |
| Initial memory | 3GB | 2GB arena + Emscripten overhead |
| Maximum memory | 4GB | wasm32 limit |
| Execute segments | 1024 | V8 JIT generates many code regions |
| Shared memory | Enabled | Worker + SharedArrayBuffer |
| Exception handling | Wasm exceptions | `-fwasm-exceptions` (not legacy) |

## Documentation

- [Architecture](ARCHITECTURE.md) — System design, invariants, code map (matklad style)
- [Agent Instructions](AGENTS.md) — For AI agents working on the codebase
- [Demo](docs/DEMO.md) — Running the demo
- [Syscall TODO](docs/SYSCALL_TODO.md) — Remaining syscalls to implement
- [Performance Plan](docs/PERFORMANCE-ACCELERATION-PLAN.md) — Acceleration research
- [Research](docs/RESEARCH-emulation-acceleration.md) — Emulation research notes

## License

Apache 2.0
