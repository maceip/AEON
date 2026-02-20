# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| master (HEAD) | Yes |

## Reporting a Vulnerability

If you discover a security vulnerability in AEON, please report it responsibly:

1. **Do NOT open a public GitHub issue** for security vulnerabilities.
2. Email security concerns to the maintainer or use [GitHub's private vulnerability reporting](https://github.com/maceip/AEON/security/advisories/new).
3. Include a description of the vulnerability, steps to reproduce, and potential impact.
4. You will receive an acknowledgment within 48 hours.

## Security Model

AEON runs untrusted RISC-V binaries inside a WebAssembly sandbox in the browser. The security boundaries are:

- **WebAssembly sandbox**: Guest code cannot escape the Wasm linear memory. All guest memory access is bounded by the 2GB arena (`addr & 0x7FFFFFFF`).
- **Syscall layer**: Only ~80 whitelisted Linux syscalls are emulated. Unknown syscalls return `-ENOSYS`.
- **Network isolation**: Guest TCP traffic is proxied through a WebTransport bridge. The guest cannot make raw socket connections — all traffic goes through the proxy.
- **Filesystem isolation**: The guest VFS is entirely in-memory (tar-backed). The guest cannot access the host filesystem unless explicitly granted via the File System Access API.
- **Cross-origin isolation**: SharedArrayBuffer requires COOP/COEP headers, which also prevent cross-origin data leaks.

## Dependency Management

- npm dependencies are audited via `npm audit` in CI.
- Rust dependencies are audited via `cargo-audit` in CI.
- Dependabot is configured for automated dependency updates.
- Trivy filesystem scanning runs on every push and weekly.
- CodeQL static analysis runs on every push for JavaScript/TypeScript.
