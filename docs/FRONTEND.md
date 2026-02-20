# Frontend

## Stack
- **Framework:** React 18 + TypeScript
- **Build:** Vite with PWA plugin (workbox)
- **Terminal:** xterm.js + WebGL addon + fit addon
- **3D:** Three.js + React Three Fiber (AppShelf3D, future holographic views)
- **Drag & Drop:** @dnd-kit/sortable
- **Styling:** Tailwind CSS + custom index.css layers

## Architecture

The frontend is a thin shell around `FriscyMachine`. The machine handles all emulator lifecycle -- boot, stdin/stdout, persistence, file mounting. The frontend renders terminal output and provides UI controls.

### Key Components

| Component | Purpose |
|-----------|---------|
| `App.tsx` | Root layout, machine instantiation, global controls |
| `TerminalView.tsx` | xterm.js wrapper, stdin/stdout wiring, drag-drop file handling |
| `SupportingView.tsx` | Side panel for apps (notepad, git, config, etc.) |
| `MachineContainer.tsx` | Machine lifecycle UI (boot, error, progress) |
| `IntroOverlay.tsx` | Boot sequence animation |
| `FuturisticNotepad.tsx` | Markdown notepad with localStorage persistence |
| `FriscyMachine.ts` | Machine orchestrator -- boot, polling, overlay persistence |

### Browser API Integration

All browser APIs are feature-detected. The app works without them.

| API | Purpose | Fallback |
|-----|---------|----------|
| File System Access | Mount local folders into `/mnt/host/` | Feature hidden |
| OPFS | Persistent overlay filesystem | No persistence |
| Keyboard Lock | Capture Ctrl+C, F-keys for terminal | Browser handles keys |
| Document PiP | Floating terminal window | `window.open()` |
| Compute Pressure | Adaptive CPU throttling | Fixed batch size |
| View Transitions | Smooth panel switching | Instant DOM swap |
| Local Font Access | User's monospace fonts | Default font |
| Window Controls Overlay | PWA title bar status | Standard title bar |
| FileSystemObserver | Watch mounted folder for changes | No auto-refresh |
| Compression Streams | Native gzip decompress for rootfs | Raw tar fetch |
| scheduler.yield() | Keep UI responsive during emulation | setInterval polling |
| Web Locks | Single-tab ownership | No coordination |
| Storage Buckets | Eviction-resistant OPFS storage | Default OPFS |
| EyeDropper | Terminal color theming | Manual hex input |

### PWA Manifest

`public/.well-known/manifest.json` declares:
- `"display_override": ["window-controls-overlay", "minimal-ui"]`
- File handlers for `.tar`, `.img` files (future)
- Launch handler for single-instance focus
