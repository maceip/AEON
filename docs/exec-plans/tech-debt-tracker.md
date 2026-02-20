# Tech Debt Tracker

Debt items sorted by priority (P0 = blocking, P1 = should fix soon, P2 = nice to have).

| # | Priority | Area | Description | Tracking |
|---|----------|------|-------------|----------|
| 1 | P0 | Persistence | Triple-write OPFS (worker + main thread + 30s loop) -- 300MB I/O every 10s | TODAY.md Phase 1A |
| 2 | P0 | Persistence | overlay.js loaded but result thrown away -- dead code path | TODAY.md Phase 1B |
| 3 | P0 | Persistence | Full VFS tar dumped instead of delta -- should be KB not MB | TODAY.md Phase 1C |
| 4 | P1 | AOT | Floating-point instructions emit `Unreachable` -- any FP guest code traps | -- |
| 5 | P1 | AOT | Atomic instructions use simplified single-thread stubs | -- |
| 6 | P1 | AOT | Dispatch loop uses linear scan instead of br_table -- O(n) vs O(1) | -- |
| 7 | P1 | Naming | Project renamed AEON but internal references still say "friscy" everywhere | -- |
| 8 | P2 | Runtime | No multi-threading -- CLONE_THREAD returns ENOSYS | -- |
| 9 | P2 | Runtime | Signal handlers registered but never asynchronously delivered | -- |
| 10 | P2 | Network | Proxy has no authentication or egress filtering | -- |
| 11 | P2 | Frontend | DesktopLayout/WindowFrame/SortableTab complexity -- should be removed given browser-as-WM decision | -- |

## Process

- When you discover new debt, add a row here.
- When debt is resolved, delete the row and note the resolving commit/PR.
- Review this file at least once per milestone.
