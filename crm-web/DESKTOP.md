# CRM Desktop App

## Overview

The CRM web application packaged as a macOS desktop app using Tauri. This provides a standalone application that automatically starts the Node.js API server in the background.

---

## Prerequisites

### System Requirements

- macOS (Intel or Apple Silicon)
- Node.js 18+ (for running the API server)
- Rust toolchain (for building Tauri)

### Install Rust

If you don't have Rust installed:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

Verify installation:

```bash
rustc --version
cargo --version
```

### Install Dependencies

```bash
cd crm-web
npm install
```

---

## Development Mode

### Running Desktop App in Dev Mode

```bash
npm run desktop:dev
```

**What This Does:**

1. Starts Vite dev server on `http://localhost:5173`
2. Opens Tauri desktop window pointing to Vite dev server
3. Automatically starts Node.js API server on port 3001 in the background
4. Enables hot-reload for UI changes

**Expected Behavior:**

- Desktop window opens with CRM interface
- Login page appears
- API calls work (authentication, customer list, export)
- Changes to React code trigger hot-reload
- API server logs appear in terminal

**Stopping:**

- Close the desktop window OR press `Ctrl+C` in terminal
- API server process is automatically terminated

---

## Production Build

### Building the Desktop App

```bash
npm run desktop:build
```

**What This Does:**

1. Runs `npm run build` to create optimized Vite bundle in `dist/`
2. Compiles Rust code for Tauri
3. Bundles everything into a macOS `.app`
4. Includes Node.js server scripts in the bundle

**Build Output Location:**

```
src-tauri/target/release/bundle/macos/CRM Desktop.app
```

**Build Time:**

- First build: 5-10 minutes (Rust compilation + dependencies)
- Subsequent builds: 1-2 minutes (incremental compilation)

### Opening the Built App

```bash
npm run desktop:open
```

Or manually:

```bash
open "src-tauri/target/release/bundle/macos/CRM Desktop.app"
```

**Expected Behavior:**

- App launches as a standalone macOS application
- No separate terminal window required
- API server starts automatically in background
- Export functionality works
- App appears in Applications folder (if moved there)

---

## Architecture

### Components

1. **Frontend (React + Vite)**
   - Built into `dist/` directory
   - Loaded by Tauri webview
   - Dev: `http://localhost:5173`
   - Prod: Local file:// URLs

2. **Backend (Node.js API)**
   - Script: `server/crm-export-server.cjs`
   - Port: 3001
   - Auto-started by Tauri on app launch
   - Auto-terminated when app closes

3. **Desktop Shell (Tauri + Rust)**
   - Native macOS window
   - Process management for Node server
   - File system access
   - Bundle packaging

### Process Flow

```
App Launch
  ↓
Tauri starts
  ↓
Spawns: node server/crm-export-server.cjs
  ↓
Opens window → Loads UI (dev: Vite, prod: dist/)
  ↓
UI makes API calls → http://127.0.0.1:3001
  ↓
App Close → Tauri terminates Node server
```

---

## API Connectivity

### Development Mode

- UI: `http://localhost:5173` (Vite dev server)
- API: `http://127.0.0.1:3001` (Node server auto-started)
- CORS: Enabled (handled by server)

### Production Mode

- UI: `file://` (bundled static files)
- API: `http://127.0.0.1:3001` (Node server auto-started)
- CORS: Enabled (same as dev)

### Testing API Manually

```bash
# Health check
curl http://127.0.0.1:3001/health

# Should return: {"ok":true}
```

---

## Known Limitations

### Current Version

1. **Single Instance**
   - Only one app instance can run at a time (port 3001 conflict)
   - Opening second instance may fail if first is running

2. **Node.js Required**
   - Node.js must be installed on the system
   - App cannot run without Node runtime

3. **Port Hardcoded**
   - API server uses fixed port 3001
   - No dynamic port selection

4. **No Auto-Updates**
   - Manual download required for new versions
   - No built-in update mechanism (could be added with Tauri updater plugin)

5. **macOS Only**
   - Current build targets macOS
   - Windows/Linux builds possible but not configured

### Future Enhancements

- [ ] Bundle Node.js runtime with app (eliminate dependency)
- [ ] Dynamic port selection with health checks
- [ ] Multiple instance support via port negotiation
- [ ] Auto-update mechanism
- [ ] Windows and Linux builds
- [ ] App icon customization
- [ ] Menu bar integration
- [ ] System tray support

---

## Troubleshooting

### Issue: "Command 'node' not found"

**Cause:** Node.js not installed or not in PATH.

**Solution:**

```bash
# Install Node.js via Homebrew
brew install node

# Or download from nodejs.org
# Verify:
node --version
```

### Issue: Desktop app opens but API calls fail

**Symptoms:**
- Login fails with network error
- Customer page shows "Failed to load"

**Debug Steps:**

1. Check if API server is running:
   ```bash
   curl http://127.0.0.1:3001/health
   ```

2. Check terminal output for errors:
   ```
   Failed to start Node API server: <error message>
   ```

3. Verify server script exists:
   ```bash
   ls server/crm-export-server.cjs
   ```

**Solution:**

- Ensure `server/crm-export-server.cjs` is present
- Check terminal for spawn errors
- Verify Node.js version (18+)

### Issue: Build fails with Rust errors

**Symptoms:**

```
error: could not compile `crm-desktop`
```

**Solution:**

1. Update Rust toolchain:
   ```bash
   rustup update
   ```

2. Clean build cache:
   ```bash
   cd src-tauri
   cargo clean
   cd ..
   npm run desktop:build
   ```

### Issue: App crashes on launch

**Debug Steps:**

1. Run from terminal to see error logs:
   ```bash
   ./src-tauri/target/release/bundle/macos/CRM\ Desktop.app/Contents/MacOS/crm-desktop
   ```

2. Check for missing dependencies:
   ```bash
   otool -L ./src-tauri/target/release/bundle/macos/CRM\ Desktop.app/Contents/MacOS/crm-desktop
   ```

### Issue: Hot-reload not working in dev mode

**Cause:** Vite dev server not accessible.

**Solution:**

- Check if port 5173 is already in use
- Stop other Vite instances:
  ```bash
  lsof -ti:5173 | xargs kill -9
  ```

### Issue: Export fails in desktop app

**Debug Steps:**

1. Open browser DevTools (in Tauri window):
   - Right-click → Inspect Element

2. Check Console for errors

3. Check Network tab for API calls

4. Verify API server is responding:
   ```bash
   curl -X POST http://127.0.0.1:3001/api/export \
     -H "Content-Type: application/json" \
     -d '{"customerIds":[1],"storeData":{"customers":[{"id":1,"name":"Test"}],"jobs":[],"notes":[]}}'
   ```

---

## File Structure

```
crm-web/
├── src/                        # React source code
├── server/
│   └── crm-export-server.cjs  # Node.js API server
├── src-tauri/                  # Tauri desktop app
│   ├── Cargo.toml             # Rust dependencies
│   ├── tauri.conf.json        # Tauri configuration
│   ├── build.rs               # Build script
│   └── src/
│       ├── main.rs            # Rust entry point
│       └── lib.rs             # Main logic (spawns Node server)
├── dist/                       # Vite build output (created by build)
├── package.json               # Desktop scripts defined here
└── DESKTOP.md                 # This file
```

---

## Development Workflow

### Typical Dev Session

```bash
# 1. Start desktop dev mode
npm run desktop:dev

# 2. Make changes to React code (hot-reload works)
# 3. Test export functionality
# 4. Check terminal for API server logs
# 5. Close app when done (API server auto-terminates)
```

### Build and Test Workflow

```bash
# 1. Lint code
npm run lint

# 2. Build desktop app
npm run desktop:build

# 3. Test built app
npm run desktop:open

# 4. Verify export works in bundled app
```

---

## Comparison: Web vs Desktop

| Feature                  | Web (npm run dev)      | Desktop (npm run desktop:dev) |
|--------------------------|------------------------|-------------------------------|
| Window Type              | Browser tab            | Native macOS window           |
| API Server               | Manual start           | Auto-starts                   |
| Hot Reload               | Yes                    | Yes                           |
| Standalone               | No (requires browser)  | Yes                           |
| Install Location         | N/A                    | Can move to /Applications     |
| Distribution             | Hosted website         | .app bundle download          |

---

## Release Checklist

Before distributing the desktop app:

- [ ] Run `npm run lint` (must pass)
- [ ] Test dev mode: `npm run desktop:dev`
- [ ] Verify login works
- [ ] Verify customer list loads
- [ ] Verify export works (select customers, export, check downloads)
- [ ] Run production build: `npm run desktop:build`
- [ ] Test bundled app: `npm run desktop:open`
- [ ] Verify all functionality in bundled app
- [ ] Check app size (src-tauri/target/release/bundle/macos/)
- [ ] Document version number
- [ ] Create release notes

---

## Summary

**Development:**
```bash
npm run desktop:dev
```

**Production Build:**
```bash
npm run desktop:build
```

**Open Built App:**
```bash
npm run desktop:open
```

**Output Location:**
```
src-tauri/target/release/bundle/macos/CRM Desktop.app
```

The desktop app provides a seamless, standalone experience with automatic API server management and native macOS integration.
