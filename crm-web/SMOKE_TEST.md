# CRM Web - Smoke Test

## Purpose
Manual verification that core CRM functionality works correctly from end to end.

---

## Prerequisites

1. **Backend server running:**
   ```bash
   cd crm-web
   node server/crm-export-server.cjs
   ```
   Should see: `CRM Export Server running on http://localhost:3001`

2. **Frontend dev server running:**
   ```bash
   cd crm-web
   npm run dev
   ```
   Should see Vite running on `http://localhost:5173/` (or similar port)

---

## Test Steps

### 1. Login Flow

1. Navigate to `http://localhost:5173/`
2. Should redirect to `/login`
3. Click "Log in" button
4. Should redirect to `/customers`
5. **PASS if:** Customers list appears with 3 entries

---

### 2. Add Job

1. From Customers page, click on "Acme Corp" (or any customer)
2. Scroll to "Add Job" section
3. Fill in:
   - Description: "Test HVAC Installation"
   - Scheduled At: Pick any future date/time
4. Click "Add Job"
5. **PASS if:** New job appears in jobs list immediately

---

### 3. Add Note (Customer-level)

1. On same customer detail page, scroll to "Add Note" section
2. Fill in:
   - Note text: "Customer prefers afternoon appointments"
   - Target: "Customer" (default)
3. Click "Add Note"
4. **PASS if:** Note appears in "Customer Notes" section immediately

---

### 4. Add Note (Job-level)

1. On same customer detail page, in "Add Note" section:
2. Fill in:
   - Note text: "Bring extra filters"
   - Target: "Job"
   - Select the job you just created
3. Click "Add Note"
4. **PASS if:** Note appears under the selected job in the jobs list

---

### 5. Refresh Persistence

1. Click browser refresh (F5 or Cmd+R)
2. Should stay on customer detail page
3. **PASS if:**
   - Job still visible
   - Both notes still visible
   - All data matches pre-refresh state

---

### 6. Export Data

1. Navigate back to Customers page (browser back or `/customers`)
2. Click "Export Data" button
3. Select 1 or more customers (checkboxes)
4. Click "Create Export"
5. **PASS if:** 
   - Export Proof table appears
   - Shows: exportId, hash, timestamp, aosProofId
   - aosProofId starts with "FALLBACK_"

---

### 7. Download Export

1. On export page, after export created, click "Download Export"
2. **PASS if:**
   - File downloads (JSON)
   - Hash Verification section appears
   - Status shows green "✓ MATCH"
   - Expected Hash matches Downloaded Hash (ETag)

---

### 8. Hash Determinism Test

1. Go back to `/export`
2. Select **same customers** as before
3. Click "Create Export" again
4. **PASS if:** Hash is **identical** to previous export (same customer selection)

---

### 9. Logout

1. Navigate to any customer detail page
2. Click "Logout" button
3. **PASS if:**
   - Redirected to `/login`
   - Attempting to visit `/customers` redirects to `/login`

---

## Expected Results Summary

| Test | Expected Outcome |
|------|------------------|
| Login | Redirects to `/customers`, shows 3 customers |
| Add Job | Job appears immediately, persists on refresh |
| Add Customer Note | Note appears in customer section |
| Add Job Note | Note appears under job |
| Refresh | All data persists |
| Create Export | Proof table with valid hash and FALLBACK proof ID |
| Download Export | Hash verification passes (green ✓) |
| Hash Determinism | Same selection → same hash |
| Logout | Redirects to login, auth protection works |

---

## Known Limitations

- Export server stores in memory only (restarting server clears exports)
- No actual AOS integration (FALLBACK mode only)
- localStorage used for CRM data (browser-specific)
- No multi-user support
- No data import capability

---

## If Test Fails

1. Check both servers are running
2. Check browser console for errors
3. Clear localStorage: `localStorage.clear()` in console
4. Refresh page
5. Try again from step 1
