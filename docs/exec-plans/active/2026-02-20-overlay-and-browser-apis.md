# AEON — Today's Implementation Plan (2026-02-20)

> Scope: What we can actually ship today. No rabbit holes.
> Rule: Each phase must be DONE before starting the next.
> Anti-scope: 3D visuals, theme polish, new UI components, MDMA/git integration, mobile.

## Key Design Decision: No Custom Window Management — Shared Machine

We are NOT building our own window tiling/tabbing/docking system. Instead:

- Users open multiple browser tabs/windows — the browser IS the window manager
- **All tabs connect to the SAME running emulator instance** — one machine, many views
- This eliminates the entire DesktopLayout/WindowFrame/SortableTab complexity

### How shared machine works:

- **First tab** boots the emulator in a `SharedWorker` (not a regular Worker)
- **Subsequent tabs** connect to the same SharedWorker — they get their own TTY/PTY (like `tmux attach`)
- The SharedWorker holds the emulator, the OPFS handles, the VFS state — it outlives any single tab
- Each tab's xterm.js connects to a different virtual terminal (the guest already supports `/dev/tty0`, `/dev/tty1`, etc.)
- `BroadcastChannel('aeon-tabs')` for tab discovery and signaling
- `Web Locks` ensure only one SharedWorker instance exists across the origin
- When ALL tabs close, the SharedWorker shuts down and auto-saves the overlay to OPFS

### What this needs:

1. **Migrate `emulator.worker.ts` from `Worker` to `SharedWorker`** — the main change. SharedWorker uses `onconnect` event and `MessagePort` per client instead of a single `postMessage`.
2. **Multiplexed stdout** — each connected tab gets its own stdout ring buffer (or a shared one with tab-id tags)
3. **Multiple PTY support** — the guest already has TTY infrastructure. Each new tab opens a new PTY.
4. **SharedArrayBuffer sharing** — SharedWorker can pass the same SABs to all connected tabs via `MessagePort.postMessage(sab)` with transfer.

---

## Phase 1: Wire Up the Overlay System (the big one)

**Why first:** Everything else depends on a working persistence + layer system.
The code is 80% written in `friscy-bundle/overlay.js` — it just isn't called.

### 1A. Kill the triple-write and unify persistence (30 min)

There are currently THREE redundant save paths writing ~300MB of I/O every 10 seconds:
1. `FriscyMachine.startAutoSave()` sends CMD_EXPORT_VFS every 10s
2. Worker `exportVFS()` writes full tar to OPFS (`persisted_rootfs.tar`) AND sends to main thread
3. Main thread `handleWorkerMessage` calls `saveOverlay()` — writes AGAIN to OPFS
4. Worker resume loop also auto-saves every 30s independently

**Do this — remove all three, replace with one clean path:**
- Remove the worker's direct OPFS write from `exportVFS()` (lines 170-174 of `emulator.worker.ts`)
- Remove the worker's 30-second auto-save in `runResumeLoop()` (lines 212-216)
- Keep `FriscyMachine.startAutoSave()` as the single trigger (every 10s, sends CMD_EXPORT_VFS)
- Worker's `exportVFS()` only sends tar to main thread via postMessage
- Main thread `handleWorkerMessage` receives it and saves via `saveOverlay()` — single write path

**Files touched:** `src/workers/emulator.worker.ts` (remove direct OPFS + 30s loop), `src/lib/FriscyMachine.ts` (clarify as single owner).

### 1B. Wire overlay restore into boot (30 min)

`FriscyMachine.ts` loads the overlay and throws it away. The worker independently restores from `persisted_rootfs.tar` in OPFS. Neither uses the overlay.js session system properly.

**IMPORTANT:** You can't just send the overlay to `/tmp/overlay.tar` — nothing reads it. The overlay must be merged with the base rootfs BEFORE the worker boots.

**Do this:**
- Keep a copy of the base rootfs (`.slice()` before transferring to worker — currently line 151 transfers it away)
- On boot: `loadOverlay(config.id)` → if it exists, `applyDelta(baseTar, delta)` → send MERGED tar to worker
- If no overlay exists, send base tar as-is
- Remove the worker's own OPFS restore (lines 379-390 of `emulator.worker.ts`) — main thread handles it now
- Create a session on first boot: `createSession(config.id, config.name)`

**Files touched:** `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts` (remove OPFS restore).

### 1C. Switch auto-save to delta persistence (30 min)

Currently saves the entire VFS tar (~100MB) every time. Switch to delta-only.

**Do this:**
- Store `this.baseTar` (the copy from 1B) as a class field on `FriscyMachine`
- In `handleWorkerMessage` on `vfs_export`: `computeDelta(this.baseTar, msg.tarData)` → `JSON.stringify(delta)` → `saveOverlay(sessionId, encodedDelta)`
- On restore (1B): `JSON.parse(loadOverlay(...))` → `applyDelta(baseTar, delta)`
- Delta for a session with a few changed files should be KB, not MB

**Files touched:** `src/lib/FriscyMachine.ts` only.

### 1D. Tar merge function for package layers (20 min)

`applyDelta` expects `{added, modified, deleted}` delta objects. Package tars are full tars, not deltas. We need a simple tar union.

**Do this — add `mergeTars()` to overlay.js:**
```js
export function mergeTars(baseTar, overlayTar) {
    const baseEntries = parseTar(baseTar);
    const overlayEntries = parseTar(overlayTar);
    const overlayPaths = new Set(overlayEntries.map(e => e.path));
    const files = [];
    // Base files not overridden by overlay
    for (const e of baseEntries) {
        if (!overlayPaths.has(e.path)) files.push({path: e.path, content: extractEntry(baseTar, e), mode: e.mode, mtime: e.mtime});
    }
    // All overlay files (overrides + additions)
    for (const e of overlayEntries) {
        files.push({path: e.path, content: extractEntry(overlayTar, e), mode: e.mode, mtime: e.mtime});
    }
    return createTar(files);
}
```

**Files touched:** `friscy-bundle/overlay.js`.

### 1E. Package layer plumbing (30 min)

**Do this:**
- Create `public/packages/manifest.json` with test entries
- On install: `fetch(url)` → `DecompressionStream('gzip')` → store tar in OPFS under `packages/{id}.tar`
- At boot, layer stack: `baseTar → mergeTars(python) → mergeTars(node) → applyDelta(userSession)`
- Use a tiny test tar with `/usr/local/bin/hello` to verify
- UI: simple checkbox list — defer to settings panel

**Files touched:** new `src/lib/PackageManager.ts`, `src/lib/FriscyMachine.ts` (boot path), minimal UI hookup.

**STOP. Test Phase 1.** Boot → create files → reload → verify changes persist via delta. Verify delta is KB not MB. Verify test package layer appears in guest FS. Verify only ONE OPFS write per save cycle.

---

## Phase 2: Improve JSPI / I/O Architecture (the performance one)

**Why second:** Phase 1 gives us layers. Phase 2 makes them fast.

### 2A. Web Locks for single-tab ownership (15 min)

SharedWorker migration is a multi-day refactor (stdin multiplexing, per-tab SABs, PTY allocation). **Defer it.** For today, use Web Locks so only one tab runs the emulator:

**Do this:**
- In `FriscyMachine.boot()`: `navigator.locks.request('aeon-machine-' + config.id, { ifAvailable: true }, ...)`
- If lock acquired: boot normally
- If lock unavailable: show "Emulator running in another tab — close it or click Take Over"
- "Take Over" button: `navigator.locks.request('aeon-machine-' + config.id, { steal: true }, ...)`
- Lock auto-releases when tab closes

**Future (not today):** SharedWorker migration for true multi-tab shared machine. Needs per-tab SABs, stdin multiplexing, and PTY allocation. Tracked separately.

**Files touched:** `src/lib/FriscyMachine.ts`.

### 2A-bis. Freehold integration — public DNS per machine (20 min)

Each machine gets its own freehold client, giving it a publicly reachable domain name.

**Do this:**
- Pull `maceip/freehold` client code (or npm package if available)
- On machine boot: start a freehold client, obtain a DNS name
- Wire the freehold tunnel to the network bridge so the guest's listening ports are externally reachable
- Display the DNS name in the UI (status bar or terminal header)

**Files touched:** `src/lib/FriscyMachine.ts`, network bridge layer, UI status display.

### 2B. Add Compression Streams for rootfs loading (15 min)

Currently the rootfs is fetched as a raw tar. Serve it gzipped and decompress natively.

**Do this:**
- In the rootfs fetch path: `fetch(url).then(r => new Response(r.body.pipeThrough(new DecompressionStream('gzip')))).then(r => r.arrayBuffer())`
- Rename rootfs files from `.tar` to `.tar.gz`
- Also use this for package overlay downloads (Phase 1C)

**Files touched:** `src/lib/FriscyMachine.ts` (fetch path), build/deploy config.

### 2C. Add scheduler.yield() to the main thread poll loop (15 min)

The 4ms `setInterval` poll loop in the main thread competes with rendering.

**Do this:**
- Replace `setInterval` with a `requestAnimationFrame` + `scheduler.yield()` loop
- Terminal output draining = `"user-blocking"` priority
- Stats updates = `"background"` priority
- Feature-detect: `if ('scheduler' in globalThis && scheduler.yield)`

**Files touched:** `src/lib/FriscyMachine.ts` or wherever the poll loop lives.

### 2D. Add Compute Pressure observer for adaptive throttle (15 min)

**Do this:**
- Create a `PressureObserver` watching `'cpu'` at 1000ms interval
- On `"serious"` or `"critical"`: reduce instructions-per-batch (post a message to worker)
- On `"nominal"`: restore full speed
- Feature-detect and gracefully degrade

**Files touched:** `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts` (accept throttle message).

**STOP. Test Phase 2.** Verify single-tab lock works → verify gzip decompress loads rootfs correctly → verify terminal stays responsive under load.

---

## Phase 3: File System Enhancements (the UX one)

### 3A. FileSystemObserver on mounted local folder (20 min)

When user mounts a local folder via `showDirectoryPicker`, watch it for changes.

**Do this:**
- After `mount_local`, create a `FileSystemObserver` on the directory handle
- On `"appeared"` / `"modified"` / `"disappeared"`: notify the worker so the guest sees updated files
- Show a subtle toast: "3 files changed in /mnt/host/"
- Feature-detect: `if ('FileSystemObserver' in globalThis)`

**Files touched:** `src/App.tsx` or `src/lib/FriscyMachine.ts`, `src/workers/emulator.worker.ts`.

### 3B. Keyboard Lock for terminal (10 min)

**Do this:**
- When terminal is focused: `navigator.keyboard.lock(['Escape', 'F1', 'F2', ..., 'F12'])`
- On blur: `navigator.keyboard.unlock()`
- This lets Ctrl+C, Escape, function keys pass through to the emulated terminal
- Feature-detect: `if ('keyboard' in navigator && navigator.keyboard.lock)`

**Files touched:** `src/components/TerminalView.tsx`.

### 3C. Document Picture-in-Picture for terminal pop-out (30 min)

The pop-out button currently opens a new browser window. PiP is better — always-on-top, survives tab switches.

**Caveat:** xterm.js WebGL addon is tied to its canvas context. Moving the DOM element kills the WebGL context. Must create a new Terminal instance in the PiP window, copy the scrollback buffer, and connect it to the same stdin/stdout.

**Do this:**
- On pop-out: `documentPictureInPicture.requestWindow({ width, height })`
- Create fresh xterm.js instance in PiP window, copy scrollback from original
- Wire PiP terminal's stdin to the same `FriscyMachine.writeStdin()`
- Wire the same stdout feed to PiP terminal's `write()`
- On PiP close: destroy PiP terminal, original stays connected
- Feature-detect and fall back to `window.open()` on unsupported browsers

**Files touched:** `src/components/TerminalView.tsx`, pop-out handler.

**STOP. Test Phase 3.** Mount a local folder → edit a file externally → verify guest sees change. Verify keyboard lock. Verify PiP terminal.

---

## Phase 4: Browser API Integration Sweep (the polish one)

Wire up every stable browser API that improves the experience. These are all small, independent, and feature-detected.

### 4A. Document-Isolation-Policy header (5 min)

Add `Document-Isolation-Policy: isolate-and-require-corp` to server response headers. May let us drop COOP/COEP headers that break third-party embeds while keeping SharedArrayBuffer.

**Files touched:** Server config / `index.html` meta tags.

### 4B. Verify JSPI growable stacks (5 min)

Chrome 137+ JSPI has growable stacks — zero overhead when a JSPI-imported function returns synchronously. Verify the current `-sJSPI=1` flag gets this automatically. Check the Emscripten version in use.

### 4C. Window Controls Overlay status bar (15 min)

Already declared in manifest: `"display_override": ["window-controls-overlay"]`. Use the reclaimed title bar area for emulator status (instruction count, CPU pressure state, OPFS sync indicator).

**Do this:**
- CSS: use `env(titlebar-area-x)`, `env(titlebar-area-width)`, etc.
- Listen to `navigator.windowControlsOverlay.ongeometrychange`
- Show: instruction counter, pause/resume, mounted folder indicator

**Files touched:** `src/App.tsx`, `src/index.css`.

### 4D. View Transitions for panel switching (15 min)

Smooth animated transitions when switching between SupportingView panels (notepad, git, config, etc.).

**Do this:**
- Wrap panel switches in `document.startViewTransition(() => { setState(...) })`
- Add `view-transition-name` to the SupportingView container
- Feature-detect: `if ('startViewTransition' in document)`

**Files touched:** `src/components/SupportingView.tsx`.

### 4E. Navigation API for emulator views (15 min)

Use `window.navigation` for proper browser back/forward between terminal, settings, package manager views.

**Do this:**
- `navigation.addEventListener('navigate', ...)` with `event.intercept()`
- Each view = a navigation entry (`/terminal`, `/settings`, `/packages`)
- Browser back button works naturally

**Files touched:** `src/App.tsx` or new `src/lib/router.ts`.

### 4F. Local Font Access for terminal (10 min)

Let users pick any installed monospace font for the terminal.

**Do this:**
- `window.queryLocalFonts()` → filter to monospace families
- Dropdown in terminal settings
- Apply via xterm.js `fontFamily` option
- Feature-detect: `if ('queryLocalFonts' in window)`

**Files touched:** `src/components/TerminalView.tsx` or settings panel.

### 4G. EyeDropper for terminal theming (5 min)

Quick color picker for terminal foreground/background/cursor colors.

**Do this:**
- `new EyeDropper().open()` → apply result to xterm.js theme
- Feature-detect: `if ('EyeDropper' in window)`

**Files touched:** Settings/theme panel.

### 4H. Storage Buckets for isolated persistence (10 min)

Separate OPFS storage into buckets with explicit eviction policies.

**Do this:**
- `navigator.storageBuckets.open('aeon-rootfs', { persisted: true, durability: 'strict' })`
- Use the bucket's storage for overlay data instead of the default OPFS root
- Prevents browser from evicting emulator data under storage pressure

**Files touched:** `friscy-bundle/overlay.js` (OPFS root calls).

**STOP. Test Phase 4.** Verify each API integration works when supported and gracefully no-ops when not.

---

## What Is NOT On Today's List

These are real work items but they are scope creep for today:

| Item | Why not today |
|------|--------------|
| I/O Worker split (separate CPU + I/O workers) | Architectural change, needs careful SharedArrayBuffer ring buffer design. Week-long project. |
| Batched JSPI / io_uring style | Requires changes to VectorHeart syscall layer in C++. Multi-day. |
| Direct Sockets / IWA | Requires packaging as Isolated Web App. Different distribution model. |
| WebGPU compute | Only useful for framebuffer rendering. Terminal-only today. |
| Tabbed Web Apps | Still experimental/origin trial. |
| Window Management multi-monitor | Nice-to-have, not blocking. |
| 3D UI polish (jedi doors, holographic machine, app rail) | Fun but not functional. |
| MDMA/git integration | Separate workstream. |
| Mobile support | Different input model, separate effort. |

### Research-Later: WASM Advances

These require deeper investigation, build system changes, and/or aren't shipped yet:

| Item | Status | Why later |
|------|--------|-----------|
| WASM Tail Calls | Shipped (Chrome 112, Wasm 3.0) | Needs `-mtail-call` flag + verify libriscv dispatch loop actually benefits. Research how the interpreter loop is structured first. |
| WASM Multi-Memory | Shipped (Wasm 3.0) | Requires libriscv patches to use separate memories for RAM vs internals. Non-trivial C++ changes. |
| WASM Memory64 | Shipped (Chrome 133) | Only needed for >4GB emulated RAM. Current 2GB arena works. Also has perf penalty vs Memory32. |
| WASM Stack Switching | Phase 3, NOT shipped | The holy grail for coroutine-style emulation. Watch for Chrome landing. Will replace JSPI for fine-grained suspend/resume. |

---

## Performance Note: Base Image Size

The smaller the base rootfs tar, the better — it directly affects:
- Boot time (download + decompress + write to emulated FS)
- Delta computation time (must parse the full base tar to diff)
- Memory usage (base tar kept in memory for delta computation)

Use `DecompressionStream('gzip')` for download (Phase 2B) and keep the base image stripped to essentials. Package layers (Python, Node) should NOT be in the base image — that's the whole point of the layer system.

---

## Verification Checklist

After all phases:

- [ ] Only ONE OPFS write per save cycle (check devtools → Application → Storage)
- [ ] Boot emulator, make changes (create files), reload page — changes persist via overlay delta
- [ ] Delta size is KB for small changes, not full-tar MB
- [ ] Install test package layer — verify `/usr/local/bin/hello` exists in guest
- [ ] Open second tab — shows "running in another tab" with Take Over button
- [ ] Mount local folder, edit file externally — guest sees update (Chrome 133+)
- [ ] Keyboard shortcuts (Ctrl+C, F1-F12) reach the terminal when focused
- [ ] Pop-out terminal floats above other windows via PiP
- [ ] Rootfs loads from `.tar.gz` with native decompression
- [ ] Under CPU pressure, emulator throttles gracefully
- [ ] Freehold client obtains DNS name on boot (displayed in UI)
