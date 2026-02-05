# RUN_LOCAL.md

## Overview

Run the CRM app on your local network with a single command or double-click. Access from any device on the same WiFi network.

---

## Quick Start

### Option 1: Double-Click (macOS)

1. Double-click **`Start CRM.command`**
2. Browser opens automatically
3. Access from other devices using the network URL shown

### Option 2: Terminal

```bash
node run-local.cjs
```

---

## Prerequisites

- **Node.js 18+** installed
- **Frontend built** (crm-web/dist/ directory exists)

If frontend is not built:

```bash
cd crm-web
npm run build
cd ..
```

---

## How It Works

### What `run-local.cjs` Does

1. Verifies frontend build exists
2. Starts API server on port **3001**
3. Starts UI server on port **3000**
4. Binds to **0.0.0.0** (LAN-accessible)
5. Opens browser automatically
6. Displays network access URLs

### What `Start CRM.command` Does

1. Checks Node.js is installed
2. Builds frontend if needed
3. Runs `run-local.cjs`
4. Keeps terminal open on error

---

## Access URLs

### Local Machine

- **UI:** http://localhost:3000
- **API:** http://localhost:3001

### Other Devices (Same Network)

- **UI:** http://192.168.x.x:3000
- **API:** http://192.168.x.x:3001

(Replace `192.168.x.x` with the IP shown in terminal)

---

## Accessing from Another Device

### Steps

1. **Start CRM** on host machine (double-click or terminal)
2. **Note the Network IP** shown in terminal output:
   ```
   Network: http://192.168.1.100:3000
   ```
3. **Connect other device** to same WiFi network
4. **Open browser** on other device
5. **Navigate to** http://192.168.1.100:3000

### Example: iPhone/iPad

1. Host machine shows: `Network: http://192.168.1.50:3000`
2. On iPhone, open Safari
3. Type: http://192.168.1.50:3000
4. CRM login page appears
5. Export works (downloads to iPhone)

### Example: Another Computer

1. Host machine shows: `Network: http://192.168.1.50:3000`
2. On other computer (same WiFi)
3. Open browser
4. Type: http://192.168.1.50:3000
5. Full CRM functionality available

---

## Shutdown

### Graceful Shutdown

Press **Ctrl+C** in terminal where `run-local.cjs` is running.

Both servers (UI and API) will stop cleanly.

### Force Quit

If Ctrl+C doesn't work:

```bash
# Find processes
lsof -ti:3000,3001

# Kill processes
lsof -ti:3000,3001 | xargs kill -9
```

### Close Command File

If launched via `Start CRM.command`, closing the terminal window stops all servers.

---

## Known Limitations

### Current Version

1. **No Authentication**
   - LocalStorage-based auth (as designed)
   - Anyone on network can access if they know the URL
   - No password protection at network level

2. **No HTTPS**
   - HTTP only (not encrypted)
   - Do not use on untrusted networks
   - Suitable for home/office LAN only

3. **Port Conflicts**
   - Ports 3000 and 3001 must be available
   - If occupied, app will fail to start
   - Change ports in `run-local.cjs` if needed

4. **No Persistent Database**
   - Data stored in browser LocalStorage
   - Data is per-browser (not shared across devices)
   - Export data manually to share

5. **Single Instance**
   - Only one instance can run at a time
   - Multiple launches on same machine will conflict

6. **macOS Auto-Open Browser**
   - Auto-open uses macOS `open` command
   - Linux: uses `xdg-open`
   - Windows: uses `start`
   - May fail on some configurations

### Network Requirements

- **Same WiFi Required:** Devices must be on same local network
- **Firewall:** Host firewall must allow ports 3000 and 3001
- **Router:** Some routers block inter-device communication (check AP isolation)

---

## Troubleshooting

### Issue: "Frontend build not found"

**Symptoms:**

```
❌ ERROR: Frontend build not found
Expected: /path/to/crm-web/dist
```

**Solution:**

Build the frontend:

```bash
cd crm-web
npm install  # First time only
npm run build
cd ..
node run-local.cjs
```

### Issue: "Port 3000 is already in use"

**Symptoms:**

```
❌ ERROR: Port 3000 is already in use
```

**Solution 1:** Kill existing process

```bash
lsof -ti:3000 | xargs kill -9
```

**Solution 2:** Change port in `run-local.cjs`

```javascript
const UI_PORT = 3002;  // Change from 3000
```

### Issue: "Cannot access from other device"

**Debug Steps:**

1. **Verify host IP:**
   ```bash
   # macOS/Linux
   ifconfig | grep "inet "
   ```

2. **Test API from host:**
   ```bash
   curl http://localhost:3001/health
   # Should return: {"ok":true}
   ```

3. **Test API from other device:**
   ```bash
   curl http://192.168.x.x:3001/health
   # Replace 192.168.x.x with host IP
   ```

4. **Check firewall:**
   - macOS: System Preferences → Security & Privacy → Firewall
   - Allow Node.js to accept incoming connections

5. **Check router:**
   - Some WiFi routers have "AP Isolation" enabled
   - This prevents devices from talking to each other
   - Disable in router settings

### Issue: "Browser doesn't open automatically"

**Cause:** Auto-open command failed.

**Solution:**

Manually open browser and navigate to:
```
http://localhost:3000
```

### Issue: "Node.js not found" (when double-clicking)

**Symptoms:**

```
❌ ERROR: Node.js is not installed
```

**Solution:**

Install Node.js:

**Option 1:** Download from https://nodejs.org

**Option 2:** Install via Homebrew (macOS)

```bash
brew install node
```

Verify installation:

```bash
node --version
```

### Issue: "Export fails from network device"

**Debug:**

1. Open browser DevTools (F12)
2. Check Console for errors
3. Check Network tab for failed requests
4. Verify API URL in frontend code uses relative paths (not hardcoded localhost)

**Check frontend code:**

```bash
cd crm-web
grep -r "localhost:3001" src/
```

Should be empty or use environment variables.

### Issue: "Data not synced across devices"

**Expected Behavior:**

Data is NOT synced. Each browser has its own LocalStorage.

**Workaround:**

1. Export data from one device
2. Import on another device (if import feature exists)
3. Or: Access CRM from same browser across devices

---

## Configuration

### Changing Ports

Edit `run-local.cjs`:

```javascript
// At top of file
const API_PORT = 3001;  // Change to 3002, 4001, etc.
const UI_PORT = 3000;   // Change to 3003, 8080, etc.
```

### Changing Host Binding

Default: `0.0.0.0` (all network interfaces)

To restrict to localhost only:

```javascript
const HOST = '127.0.0.1';  // Localhost only (not LAN-accessible)
```

To bind to specific IP:

```javascript
const HOST = '192.168.1.50';  // Specific IP only
```

---

## Technical Details

### Architecture

```
┌─────────────────────────────────────────┐
│  run-local.cjs                          │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────┐  ┌──────────────┐ │
│  │  UI Server      │  │  API Server  │ │
│  │  Port 3000      │  │  Port 3001   │ │
│  │  Serves dist/   │  │  Node.js     │ │
│  └─────────────────┘  └──────────────┘ │
│         ↓                     ↓         │
│    0.0.0.0:3000          0.0.0.0:3001  │
└─────────────────────────────────────────┘
                    ↓
            LAN Accessible
                    ↓
    ┌───────────────┴───────────────┐
    ↓                               ↓
Browser (localhost)          Browser (192.168.x.x)
```

### UI Server

- **Type:** Node.js http server
- **Function:** Serves static files from `crm-web/dist/`
- **SPA Routing:** All non-file requests → index.html
- **MIME Types:** Proper content-type headers for JS/CSS/images
- **CORS:** Not needed (same-origin for API calls)

### API Server

- **Script:** `crm-web/server/crm-export-server.cjs`
- **Function:** Export API, health check
- **CORS:** Already configured in existing server
- **Process:** Spawned as child process, inherits stdio

### Process Management

- **Parent:** `run-local.cjs`
- **Child 1:** API server (Node.js)
- **Child 2:** UI server (http.Server)
- **Cleanup:** SIGINT/SIGTERM handlers for graceful shutdown

---

## File Structure

```
Robo-code/
├── run-local.cjs              # Main runner (Terminal)
├── Start CRM.command          # Double-click launcher (macOS)
├── RUN_LOCAL.md              # This file
└── crm-web/
    ├── dist/                  # Built frontend (required)
    │   └── index.html
    └── server/
        └── crm-export-server.cjs  # API server
```

---

## Comparison: Local vs Desktop App

| Feature                  | Local Runner        | Desktop App (Tauri)     |
|--------------------------|---------------------|-------------------------|
| Launch Method            | Double-click .command | Double-click .app      |
| Window Type              | Browser             | Native macOS window     |
| LAN Access               | ✅ Yes              | ❌ No (localhost only)  |
| Multi-Device             | ✅ Yes              | ❌ No                   |
| Requires Build           | Frontend only       | Frontend + Rust         |
| Auto-Start API           | ✅ Yes              | ✅ Yes                  |
| Distribution             | Copy files          | Copy .app bundle        |

**Use Local Runner When:**
- Need to access from multiple devices
- Want to share on home/office network
- Don't need native desktop features

**Use Desktop App When:**
- Single-user, single-device use
- Want native macOS integration
- Want .app in Applications folder

---

## Security Considerations

### Local Network Only

- **Intended Use:** Home or office LAN
- **NOT for public internet:** No authentication, no HTTPS
- **Firewall:** Recommended on host machine

### Data Privacy

- Data stored in browser LocalStorage (client-side)
- API server doesn't persist data
- Export downloads are local to each device

### Recommended Practices

1. **Use on trusted networks only** (home WiFi, office LAN)
2. **Do not expose to internet** (no port forwarding)
3. **Close app when not in use** (frees ports, stops servers)
4. **Check who's on network** before sharing sensitive data

---

## Development vs Production

### This Runner is Production-Ready

- Uses built frontend (dist/)
- No hot-reload
- Optimized bundles
- Suitable for end users

### For Development

Use existing dev workflow:

```bash
cd crm-web

# Terminal 1: API server
node server/crm-export-server.cjs

# Terminal 2: Vite dev server
npm run dev
```

Or use desktop dev mode:

```bash
cd crm-web
npm run desktop:dev
```

---

## Manual UI Test Checklist

Use this checklist to verify the CRM is working correctly after launch:

### Basic Functionality

- [ ] **Login**: Click "Log in" button → redirects to Customers page
- [ ] **Customer List**: See all 8 customers in table format
- [ ] **Customer Detail**: Click customer name → detail page loads
- [ ] **Back Navigation**: Click "← Back to Customers" → returns to list
- [ ] **Logout**: Click "Logout" → returns to login page

### Customer Detail Page

- [ ] **Customer Info**: Name, email, phone displayed correctly
- [ ] **Jobs List**: All jobs for customer shown with status badges
- [ ] **Job Notes**: Notes under jobs displayed properly
- [ ] **Customer Notes**: Notes section shows customer-level notes
- [ ] **Add Job**: Fill form → click "Add Job" → new job appears
- [ ] **Add Customer Note**: Write note → select "Customer" → click "Add Note" → appears in list
- [ ] **Add Job Note**: Write note → select "Specific Job" → choose job → click "Add Note" → appears under job

### Export Functionality

- [ ] **Navigate to Export**: From customers page → click "📊 Export Data" button
- [ ] **Select Customers**: Checkboxes work, "Select All" / "Deselect All" works
- [ ] **Create Export**: Select customers → click "📤 Create Export" → success message
- [ ] **Download Export**: Click "💾 Download Export" → file downloads
- [ ] **Hash Verification**: Verification section shows "✅ MATCH" (green)
- [ ] **Back to Customers**: Click "← Back to Customers" → returns to list

### Data Persistence

- [ ] **Refresh Test**: Add job/note → refresh page → data still present
- [ ] **LocalStorage**: Data survives browser close/reopen

### LAN Access (Requires Second Device)

- [ ] **Network URL**: Access from phone/tablet using `http://192.168.x.x:3000`
- [ ] **Login Works**: Can log in from network device
- [ ] **Browse Customers**: Customer list loads on network device
- [ ] **Export Works**: Can create and download export from network device

### Visual/UX

- [ ] **Layout**: No broken layouts, buttons aligned properly
- [ ] **Colors**: Status badges colored correctly (green/yellow/blue/red)
- [ ] **Forms**: All form inputs clearly labeled
- [ ] **Tables**: Customer table readable with proper spacing
- [ ] **No Console Errors**: Open browser DevTools → no red errors

---

## Known Limitations (Demo)

### Data Management

- **No Central Database**: Each browser has its own data (LocalStorage)
- **No Sync**: Data on one device doesn't sync to others
- **No Backup**: Clearing browser data deletes all CRM data
- **No Import**: Can't import previously exported data back into CRM

### Multi-User

- **No Real Auth**: Login button is just a placeholder (no password)
- **No User Accounts**: All users share the same data on same browser
- **No Permissions**: No role-based access control

### Data Size

- **LocalStorage Limit**: Typically 5-10 MB per domain
- **Large Datasets**: Performance may degrade with hundreds of customers

### Network

- **Same WiFi Required**: Devices must be on same local network
- **No Internet Access**: CRM only accessible on LAN (not public internet)
- **Firewall**: Host machine may block incoming connections (check settings)

### Export

- **File Download Only**: Export produces JSON file (no cloud storage)
- **Manual Process**: No scheduled/automatic exports
- **AOS Proof**: Proof ID generated but not verified against blockchain (demo mode)

### Features Not Included

- **No Email Integration**: Can't send emails to customers
- **No Calendar Integration**: Jobs don't sync to calendar apps
- **No File Attachments**: Can't attach files to jobs/notes
- **No Search**: No search/filter functionality
- **No Reports**: No analytics or reporting features
- **No Edit/Delete**: Can't edit or delete existing jobs/notes (only add)

### Browser Compatibility

- **Modern Browsers Only**: Tested on Chrome, Firefox, Safari (latest versions)
- **No IE Support**: Internet Explorer not supported

---

## Summary

**Terminal:**
```bash
node run-local.cjs
```

**Double-Click:**
```
Start CRM.command
```

**Access Local:**
```
http://localhost:3000
```

**Access Network:**
```
http://192.168.x.x:3000
```

**Shutdown:**
```
Ctrl+C
```

Simple. Fast. LAN-accessible.
