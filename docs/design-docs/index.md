# Design Docs -- ADR Log

Architecture Decision Records, newest first.

| # | Title | Status | Date |
|---|-------|--------|------|
| 005 | Browser as window manager (no custom tiling) | Accepted | 2026-02 |
| 006 | Overlay layers for persistence (Docker-style) | Accepted | 2026-02 |
| 007 | JSPI over Asyncify for async I/O | Accepted | 2026-02 |
| 008 | Single persistence write path | Accepted | 2026-02 |
| 009 | Freehold for public DNS per machine | Accepted | 2026-02 |
| 004 | Emscripten over hand-rolled Wasm | Accepted | 2025-01 |
| 003 | libriscv as interpreter core | Accepted | 2025-01 |
| 002 | RISC-V as target ISA | Accepted | 2025-01 |
| 001 | Userland emulation over full-system | Accepted | 2025-01 |

## How to add a new ADR

1. Create `docs/design-docs/NNN-short-title.md`.
2. Use the template: **Context -> Decision -> Consequences**.
3. Add a row to this table.
4. Link from [AGENTS.md](../../AGENTS.md) if it changes a top-level concern.
