# Security

## Threat Model

AEON runs untrusted Linux binaries inside a WebAssembly sandbox. The primary security boundary is the Wasm execution environment -- guest code cannot escape to the host except through explicitly implemented syscalls.

### Trust boundaries

| Boundary | Trust level |
|----------|------------|
| Wasm sandbox (browser) | Fully trusted -- browser enforces memory isolation |
| libriscv interpreter | Trusted -- emulates RISC-V in linear memory |
| Syscall layer (`syscalls.hpp`) | Semi-trusted -- validates all guest pointers |
| VFS (`vfs.hpp`) | Semi-trusted -- tar-backed, in-memory |
| OPFS persistence (`overlay.js`) | Trusted -- origin-scoped, browser-managed |
| File System Access API (`/mnt/host/`) | User-granted -- explicit permission per folder |
| VectorHeart JSPI bridge | Trusted -- mediates all async I/O |
| Network bridge (WebTransport) | Untrusted -- proxies to host-side Go server |
| Host proxy (`proxy/`) | Trusted on host -- opens real TCP/UDP sockets |
| Freehold DNS tunnel | Semi-trusted -- exposes guest ports to internet |

### Sandbox Properties

- **Memory isolation:** Guest RISC-V code runs in Wasm linear memory (2GB arena). It cannot access browser memory, DOM, or other tabs.
- **Filesystem isolation:** The VFS is in-memory from a tar archive. `/mnt/host/` requires explicit user permission via File System Access API.
- **Network isolation:** Socket syscalls go through the network bridge to the proxy. Without the proxy, networking is unavailable. Freehold tunnels expose specific ports -- not the full network namespace.
- **Cross-tab isolation:** Web Locks prevent multiple tabs from writing to OPFS simultaneously. Each tab either owns the machine or is a viewer.

### Attack Surface

- **Syscall layer.** Incorrect pointer validation could let a guest read/write outside its arena. All accesses use libriscv's bounds-checked API.
- **Network proxy.** A guest could scan the host network or connect to internal services. The proxy should have egress filtering.
- **Freehold tunnel.** Publicly exposes guest-listening ports. The guest controls what it serves. Rate limiting and abuse detection are the proxy's responsibility.
- **OPFS persistence.** Malicious overlay data could cause unexpected behavior on restore. Tar parsing must reject malformed entries.
- **Package layers.** Downloaded tars from CDN must be integrity-checked (SRI hash or similar).

### Recommendations

1. Run the network proxy behind a firewall with egress filtering.
2. Integrity-check package layer tars before applying.
3. Set Content-Security-Policy headers on the served bundle.
4. Use Document-Isolation-Policy for cross-origin isolation (replaces COOP/COEP).
5. Rate-limit freehold tunnel connections.
