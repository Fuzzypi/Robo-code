# CRM Web - Release Notes

## What This Is

A **local-first CRM demo** with verifiable export capabilities.

This is a proof-of-concept demonstrating:

- Customer/Job/Note data management
- Local persistence (browser localStorage)
- Deterministic export with cryptographic hash verification
- Auth-protected routing
- AOS-ready architecture (currently in FALLBACK mode)

---

## What This Is NOT

- **Not production-ready** - No security hardening, no data validation beyond basics
- **Not multi-user** - Single browser, single localStorage namespace
- **Not networked** - Backend runs locally only (localhost:3001)
- **Not integrated with AOS** - Uses FALLBACK mode for all exports
- **Not persistent beyond browser** - Clear localStorage = lose all data
- **Not optimized** - No pagination, no search, no performance tuning

---

## Core Features

### ✅ Implemented

- **Authentication**: Token-based (localStorage), login/logout flow
- **Customers**: View list, drill into details
- **Jobs**: Add jobs to customers, view scheduled times
- **Notes**: Add notes to customers OR specific jobs
- **Export**: Select customers, create deterministic export
- **Proof**: SHA-256 hash, ETag verification, download with proof headers
- **Persistence**: All CRM data stored in `localStorage` key `crm_store_v1`
- **Error Handling**: Error boundaries, graceful fallbacks

---

## Known Limitations

### Data

- No import capability
- No edit/delete functionality
- No customer creation UI
- Hardcoded initial seed (3 customers, 1 job, 1 note)

### Export

- In-memory storage only (server restart clears exports)
- No export history UI
- No re-verification of old exports
- FALLBACK proof IDs only (no real AOS attestation)

### UI/UX

- Minimal styling (functional only)
- No loading spinners
- No optimistic updates
- No keyboard shortcuts
- No accessibility testing

### Deployment

- Requires two separate processes (API server + dev server)
- No production build tested
- No Docker/containerization
- No environment configuration

---

## Technical Stack

- **Frontend**: React 18, Vite, react-router-dom
- **Backend**: Node.js (plain http module, zero dependencies)
- **Storage**: Browser localStorage
- **Crypto**: SHA-256 via Node crypto module
- **Auth**: Token in localStorage (no encryption)

---

## Running Locally

### Start Backend

```bash
cd crm-web
node server/crm-export-server.cjs
```

### Start Frontend

```bash
cd crm-web
npm run dev
```

Visit `http://localhost:5173/` (or port shown by Vite)

---

## Future Roadmap (Not Implemented)

- Real AOS integration (replace FALLBACK mode)
- Customer CRUD operations
- Job status updates
- Note editing/deletion
- Export history and re-verification
- Search and filtering
- Multi-user support
- Network deployment
- Production hardening

---

## Version

- **Phase**: 5 (Hardening + Demo Readiness)
- **Date**: February 4, 2026
- **Status**: Local demo only

---

## Support

This is a demo/proof-of-concept. No support or warranty provided.
Use at your own risk. Data loss possible. Not for production use.
