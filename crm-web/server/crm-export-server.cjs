const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 3001;
const STORE_KEY = 'crm_store_v1';

// In-memory storage for exports
const exportStorage = new Map();

function generateUUID() {
  return crypto.randomUUID();
}

function computeHash(data) {
  return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
}

function loadStoreFromLocalStorage() {
  // Since we can't access browser localStorage from Node,
  // we'll accept the data from the request payload
  return null;
}

function normalizeExportData(storeData, customerIds) {
  const normalizedIds = customerIds.map(id => parseInt(id)).sort((a, b) => a - b);
  
  const customers = storeData.customers
    .filter(c => normalizedIds.includes(c.id))
    .sort((a, b) => a.id - b.id);
  
  const jobs = storeData.jobs
    .filter(j => normalizedIds.includes(j.customerId))
    .sort((a, b) => a.id - b.id);
  
  const customerAndJobIds = [
    ...normalizedIds,
    ...jobs.map(j => j.id)
  ];
  
  const notes = storeData.notes
    .filter(n => {
      if (n.parentType === 'customer') {
        return normalizedIds.includes(n.parentId);
      } else if (n.parentType === 'job') {
        return jobs.some(j => j.id === n.parentId);
      }
      return false;
    })
    .sort((a, b) => a.id - b.id);
  
  return { customers, jobs, notes };
}

function handleRequest(req, res) {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  
  // GET /health
  if (req.method === 'GET' && url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));
    return;
  }
  
  // POST /api/export
  if (req.method === 'POST' && url.pathname === '/api/export') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const { customerIds, storeData } = payload;
        
        if (!customerIds || !Array.isArray(customerIds)) {
          console.error('[ERROR] Invalid request: customerIds must be an array');
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'customerIds array required' }));
          return;
        }
        
        if (!storeData || typeof storeData !== 'object') {
          console.error('[ERROR] Invalid request: storeData must be an object');
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'storeData object required' }));
          return;
        }

        if (!storeData.customers || !storeData.jobs || !storeData.notes) {
          console.error('[ERROR] Invalid storeData: missing required fields');
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'storeData missing customers, jobs, or notes' }));
          return;
        }
        
        // Normalize and prepare export data
        const exportData = normalizeExportData(storeData, customerIds);
        
        // Compute deterministic hash
        const hash = computeHash(exportData);
        const exportId = generateUUID();
        const timestamp = new Date().toISOString();
        
        // AOS fallback - since AOS is not required to be running
        const aosProofId = `FALLBACK_${generateUUID()}`;
        
        console.log(`[INFO] Export created: ${exportId}, hash: ${hash}`);
        
        // Store export
        exportStorage.set(exportId, {
          exportId,
          hash,
          timestamp,
          aosProofId,
          data: exportData
        });
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          exportId,
          hash,
          timestamp,
          aosProofId
        }));
      } catch (err) {
        console.error('[ERROR] Export failed:', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }
  
  // GET /api/export/:id/download
  if (req.method === 'GET' && url.pathname.startsWith('/api/export/')) {
    const pathParts = url.pathname.split('/');
    if (pathParts.length === 5 && pathParts[4] === 'download') {
      const exportId = pathParts[3];
      const exportRecord = exportStorage.get(exportId);
      
      if (!exportRecord) {
        console.error(`[ERROR] Export not found: ${exportId}`);
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Export not found' }));
        return;
      }
      
      console.log(`[INFO] Download requested: ${exportId}`);
      
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'ETag': `"${exportRecord.hash}"`,
        'X-AOS-Proof-Id': exportRecord.aosProofId,
        'Content-Disposition': `attachment; filename="export-${exportId}.json"`
      });
      res.end(JSON.stringify(exportRecord.data, null, 2));
      return;
    }
  }
  
  // 404
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
}

const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log(`CRM Export Server running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
