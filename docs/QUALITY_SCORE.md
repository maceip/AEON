# Quality Score

## Rubric

Quality is tracked across five dimensions. Each is scored 1-5 where 3 means "acceptable for a small team" and 5 means "production-grade".

| Dimension | Current | Target | Notes |
|-----------|---------|--------|-------|
| **Correctness** | 4 | 5 | ~84 syscalls implemented; JIT integer translation verified |
| **Reliability** | 2 | 4 | Persistence is broken (triple-write, overlay dead code); crash recovery untested |
| **Performance** | 3 | 5 | Interpreter ~40% native; JIT ~80%; JSPI adds latency on every I/O |
| **Security** | 3 | 4 | Wasm sandbox is strong; network proxy needs auth; freehold trust model TBD |
| **Developer UX** | 2 | 4 | Terminal works; overlay/package system not wired; no multi-tab |

## Metrics (to instrument)

- **Boot time** -- time from page load to first shell prompt.
- **Delta size** -- bytes written to OPFS per save cycle (target: KB, not MB).
- **JSPI suspension count** -- how often the guest freezes for async I/O per second.
- **Instruction throughput** -- MIPS sustained during normal terminal usage.
- **Memory overhead** -- Wasm linear memory allocated vs guest memory actually used.

## SLOs (aspirational)

| SLO | Target |
|-----|--------|
| Shell interactive within 2s of page load | 90% |
| Delta save under 100KB for typical session changes | 95% |
| Zero syscall panics on supported test suite | 100% |
| JIT-compiled code matches interpreter output | 100% |
| Second tab connects to running machine within 500ms | 90% |
