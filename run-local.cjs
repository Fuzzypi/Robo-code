#!/usr/bin/env node
/**
 * run-local.cjs
 * 
 * Single-command local runner for CRM app.
 * Starts API server + serves frontend on LAN-accessible address.
 * 
 * Usage:
 *   node run-local.cjs
 *   ./run-local.cjs
 */

const http = require('http');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const { execSync } = require('child_process');

// Configuration
const API_PORT = 3001;
const UI_PORT = 3000;
const HOST = '0.0.0.0'; // LAN-accessible

// Paths
const PROJECT_ROOT = __dirname;
const CRM_WEB_DIR = path.join(PROJECT_ROOT, 'crm-web');
const DIST_DIR = path.join(CRM_WEB_DIR, 'dist');
const SERVER_SCRIPT = path.join(CRM_WEB_DIR, 'server', 'crm-export-server.cjs');

// Process tracking
let apiProcess = null;
let uiServer = null;

/**
 * Get local network IP address
 */
function getLocalIP() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Skip internal (loopback) and non-IPv4 addresses
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  
  return '127.0.0.1';
}

/**
 * Check if frontend build exists
 */
function checkFrontendBuild() {
  if (!fs.existsSync(DIST_DIR)) {
    console.error('\n❌ ERROR: Frontend build not found');
    console.error(`Expected: ${DIST_DIR}`);
    console.error('\nPlease build the frontend first:');
    console.error('  cd crm-web && npm run build\n');
    process.exit(1);
  }
  
  const indexPath = path.join(DIST_DIR, 'index.html');
  if (!fs.existsSync(indexPath)) {
    console.error('\n❌ ERROR: index.html not found in build');
    console.error(`Expected: ${indexPath}\n`);
    process.exit(1);
  }
}

/**
 * Check if API server script exists
 */
function checkAPIServer() {
  if (!fs.existsSync(SERVER_SCRIPT)) {
    console.error('\n❌ ERROR: API server not found');
    console.error(`Expected: ${SERVER_SCRIPT}\n`);
    process.exit(1);
  }
}

/**
 * Start the API server
 */
function startAPIServer() {
  return new Promise((resolve, reject) => {
    console.log(`\n🚀 Starting API server on port ${API_PORT}...`);
    
    apiProcess = spawn('node', [SERVER_SCRIPT], {
      env: {
        ...process.env,
        PORT: API_PORT.toString(),
        HOST: HOST
      },
      stdio: 'inherit'
    });
    
    apiProcess.on('error', (err) => {
      console.error('❌ Failed to start API server:', err.message);
      reject(err);
    });
    
    apiProcess.on('exit', (code, signal) => {
      if (code !== null && code !== 0) {
        console.log(`\n⚠️  API server exited with code ${code}`);
      }
      if (signal) {
        console.log(`\n⚠️  API server killed by signal ${signal}`);
      }
    });
    
    // Give API server time to start
    setTimeout(() => {
      console.log('✅ API server started');
      resolve();
    }, 1000);
  });
}

/**
 * Start the UI server (serves static files from dist/)
 */
function startUIServer() {
  return new Promise((resolve, reject) => {
    console.log(`\n🌐 Starting UI server on port ${UI_PORT}...`);
    
    // MIME types for static files
    const mimeTypes = {
      '.html': 'text/html',
      '.js': 'application/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
      '.woff': 'font/woff',
      '.woff2': 'font/woff2',
      '.ttf': 'font/ttf',
      '.eot': 'application/vnd.ms-fontobject'
    };
    
    uiServer = http.createServer((req, res) => {
      // Parse URL and remove query string
      let filePath = req.url.split('?')[0];
      
      // Handle SPA routing - serve index.html for non-file requests
      if (!path.extname(filePath)) {
        filePath = '/index.html';
      }
      
      // Prevent directory traversal
      filePath = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
      
      const fullPath = path.join(DIST_DIR, filePath);
      
      // Check if file exists
      fs.access(fullPath, fs.constants.R_OK, (err) => {
        if (err) {
          // File not found - serve index.html for SPA routing
          const indexPath = path.join(DIST_DIR, 'index.html');
          fs.readFile(indexPath, (readErr, data) => {
            if (readErr) {
              res.writeHead(404);
              res.end('404 Not Found');
              return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data);
          });
          return;
        }
        
        // Read and serve file
        fs.readFile(fullPath, (readErr, data) => {
          if (readErr) {
            res.writeHead(500);
            res.end('500 Internal Server Error');
            return;
          }
          
          // Determine content type
          const ext = path.extname(fullPath);
          const contentType = mimeTypes[ext] || 'application/octet-stream';
          
          res.writeHead(200, { 'Content-Type': contentType });
          res.end(data);
        });
      });
    });
    
    uiServer.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`\n❌ ERROR: Port ${UI_PORT} is already in use`);
        console.error('Please stop the other process or change UI_PORT in run-local.cjs\n');
      } else {
        console.error('❌ UI server error:', err.message);
      }
      reject(err);
    });
    
    uiServer.listen(UI_PORT, HOST, () => {
      console.log('✅ UI server started');
      resolve();
    });
  });
}

/**
 * Open browser
 */
function openBrowser(url) {
  const platform = process.platform;
  const commands = {
    darwin: 'open',
    win32: 'start',
    linux: 'xdg-open'
  };
  
  const command = commands[platform];
  if (!command) {
    console.log(`\n⚠️  Cannot auto-open browser on ${platform}`);
    return;
  }
  
  try {
    console.log(`\n🌍 Opening browser: ${url}`);
    execSync(`${command} ${url}`, { stdio: 'ignore' });
  } catch (err) {
    console.log('⚠️  Failed to auto-open browser');
  }
}

/**
 * Cleanup on exit
 */
function cleanup() {
  console.log('\n\n🛑 Shutting down...');
  
  if (apiProcess) {
    console.log('  → Stopping API server...');
    apiProcess.kill('SIGTERM');
  }
  
  if (uiServer) {
    console.log('  → Stopping UI server...');
    uiServer.close();
  }
  
  console.log('✅ Shutdown complete\n');
  process.exit(0);
}

/**
 * Main execution
 */
async function main() {
  console.log('═══════════════════════════════════════════════');
  console.log('  CRM Local Network Runner');
  console.log('═══════════════════════════════════════════════');
  
  // Pre-flight checks
  checkFrontendBuild();
  checkAPIServer();
  
  // Get network info
  const localIP = getLocalIP();
  
  try {
    // Start servers
    await startAPIServer();
    await startUIServer();
    
    // Display access information
    console.log('\n═══════════════════════════════════════════════');
    console.log('✅ CRM is running!');
    console.log('═══════════════════════════════════════════════');
    console.log('\n📍 Access URLs:');
    console.log(`   Local:   http://localhost:${UI_PORT}`);
    console.log(`   Network: http://${localIP}:${UI_PORT}`);
    console.log('\n📡 API Server:');
    console.log(`   Local:   http://localhost:${API_PORT}`);
    console.log(`   Network: http://${localIP}:${API_PORT}`);
    console.log('\n💡 To access from another device:');
    console.log(`   1. Connect to the same WiFi network`);
    console.log(`   2. Open: http://${localIP}:${UI_PORT}`);
    console.log('\n⌨️  Press Ctrl+C to stop');
    console.log('═══════════════════════════════════════════════\n');
    
    // Open browser
    openBrowser(`http://localhost:${UI_PORT}`);
    
  } catch (err) {
    console.error('\n❌ Failed to start:', err.message);
    cleanup();
  }
}

// Register cleanup handlers
process.on('SIGINT', cleanup);  // Ctrl+C
process.on('SIGTERM', cleanup); // kill
process.on('exit', cleanup);    // Normal exit

// Run
main().catch((err) => {
  console.error('\n❌ Fatal error:', err);
  process.exit(1);
});
