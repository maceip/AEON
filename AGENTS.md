# AGENTS.md

Instructions for AI agents working on this codebase.

## Project Overview

AEON is a browser-native RISC-V Linux emulator. It runs real Linux binaries (from Docker container images) inside a WebAssembly emulator in the browser, with JSPI-based async I/O, a JIT compiler (RISC-V -> Wasm), and OPFS-based persistence with overlay filesystem layers.

Read `ARCHITECTURE.md` first. It is the source of truth for how the system works.

## Agent Coordination

Multiple agents may work on this codebase simultaneously. Coordination happens through:

- **`docs/exec-plans/active/`** -- current execution plans. Check here before starting work.
- **`TODAY.md`** -- the day's prioritized implementation plan. Phases are sequential.
- **`work-tasks.md`** -- inter-agent task queue. Append tasks to the bottom. Mark completed tasks with `[x]`.

When you start working on a task, note it in the relevant exec plan. When you finish, update the plan's progress section with what you did and any surprises encountered.

## Code Layout

| Path | What lives there |
|------|------------------|
| `runtime/` | C++ emulator: libriscv integration, syscall handlers, VFS, ELF loader |
| `runtime/library_vectorheart.js` | VectorHeart JSPI bridge -- the async I/O layer between guest syscalls and browser APIs |
| `aot/` | Rust AOT compiler (`rv2wasm`): RISC-V ELF to standalone Wasm |
| `aot-jit/` | Rust JIT tier: `rv2wasm` compiled to wasm32 via wasm-bindgen |
| `friscy-bundle/` | Browser deployment: HTML shell, Worker, JIT manager, network bridge, overlay.js |
| `src/` | React frontend: TypeScript + Vite |
| `src/lib/FriscyMachine.ts` | Machine lifecycle -- boot, polling, persistence, stdin/stdout orchestrator |
| `src/workers/emulator.worker.ts` | Vite-mode Web Worker for the React frontend |
| `vendor/libriscv/` | RISC-V emulator library (upstream, with local patches) |
| `proxy/` | Go WebTransport-to-TCP network proxy |
| `sync-server/` | WebSocket sync server for multi-device state sync |
| `tests/` | Integration tests (Node.js + Playwright scripts) |
| `docs/` | All documentation beyond ARCHITECTURE.md |

## Architecture Invariants (DO NOT VIOLATE)

1. The Worker thread never touches the DOM.
2. Syscall handlers never call `machine.simulate()` or `machine.resume()`.
3. The simulate loop never does I/O directly -- all I/O goes through syscall handlers or `EM_ASM` bridges.
4. `postMessage` is only used for setup -- runtime communication uses SharedArrayBuffer + Atomics.
5. JSPI-suspended functions (`js_opfs_io`, `js_net_proxy`, `js_dns_resolve`) never throw into the C++ stack. They catch internally and return -1 on error.
6. Sync fast-path functions (`js_compute_offload`, `js_gettime_ms`) are NOT on JSPI_IMPORTS -- zero suspension overhead.
7. Persistence has ONE write path. Do not add redundant OPFS writes. See TODAY.md Phase 1A.

## Quality Standards

- No mocked or simulated implementations. Real tests against real behavior.
- Feature-detect all browser APIs. Graceful degradation is mandatory.
- No Asyncify (`-sASYNCIFY`). Use JSPI (`-sJSPI=1`) for async I/O.
- Wasm exceptions must be final-spec (`-fwasm-exceptions`), never legacy.
- Every exec plan must be self-contained: a novice with only the repo and the plan should succeed end-to-end.

## Common Pitfalls

1. **rootfsData transfer:** `postMessage(data, [data])` transfers ownership -- the sender loses the ArrayBuffer. `.slice()` first if you need to keep a copy.
2. **OPFS in Workers only:** `createSyncAccessHandle()` only works in dedicated Workers, not the main thread.
3. **SharedArrayBuffer requires cross-origin isolation:** COOP/COEP headers (or Document-Isolation-Policy) must be set.
4. **Arena is 31-bit (2GB):** Guest addresses are `addr & 0x7FFFFFFF`. The remaining ~1GB is Emscripten's heap.
5. **JIT invalidation:** When `mprotect(PROT_WRITE)` hits a JIT'd page, the compiled function must be evicted.
6. **`applyDelta` vs `mergeTars`:** `applyDelta` takes `{added, modified, deleted}` delta objects. Package tars need `mergeTars` (tar union). They are different operations.

## Exec Plan Format

Plans in `docs/exec-plans/active/` follow this structure:

```markdown
# [Title]

## Purpose
What the user can do after this change that they could not do before.

## Context
Current state, key files, terminology defined in plain language.

## Plan of Work
Sequence of concrete edits with file paths.

## Validation
Observable behavior verification -- not just "tests pass" but what a human sees.

## Progress
- [ ] Step 1 (timestamp when started/completed)
- [ ] Step 2

## Surprises & Discoveries
Unexpected findings with evidence.

## Decision Log
All decisions with rationale and dates.
```

Plans must be self-contained. Every term of art must be defined in plain language or not used.
