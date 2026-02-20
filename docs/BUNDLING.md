# Single-Binary Distribution

Investigation into packaging AEON as a distributable binary.

## Constraints

- `rootfs.tar` is ~99 MB (cannot inline into HTML)
- `friscy.wasm` is ~547 KB, JIT compiler ~288 KB
- SharedArrayBuffer requires COOP/COEP headers (no `file://` protocol)
- Web Workers require proper MIME types

## Recommended: Tauri v2

**Tauri v2** is the best fit for AEON's constraints:

1. **SharedArrayBuffer**: Tauri's `tauri.conf.json` supports custom COOP/COEP headers on its `tauri://` protocol.
2. **Large assets**: rootfs.tar ships as a [resource file](https://v2.tauri.app/develop/resources/) alongside the binary — no compile-time embedding.
3. **Distribution**: Produces `.msi` (Windows), `.dmg` (macOS), `.AppImage` (Linux).
4. **Vite integration**: First-class via `@tauri-apps/cli` + `vite-plugin-tauri`.
5. **Binary size**: ~3-5 MB native binary + assets.

### Setup Steps

```bash
npm install -D @tauri-apps/cli@next
npx tauri init
# Configure tauri.conf.json with COOP/COEP headers and resource paths
npx tauri build
```

## Alternative: Rust + axum Server

A custom Rust binary with embedded HTTP server:
- Serves dist/ on localhost with correct headers
- Opens system browser (full WebAPI support)
- rootfs.tar as sidecar file
- ~2-5 MB compiled binary

## Not Viable

| Approach | Why Not |
|----------|---------|
| Single HTML file | SharedArrayBuffer blocked on `file://`, 132MB base64 chokes browser |
| Pake | Designed for remote URLs, no sidecar mechanism |
| Neutralinojs | No documented COOP/COEP header support |
| Servo embedded | Incomplete web platform, not production-ready |

## maceip/agent-file

The `agent-file` repo is a fork of [Letta Agent File](https://github.com/letta-ai/agent-file) — an open format (`.af`) for serializing AI agents. It is **not** a web app bundler and has no relevance to this task.
