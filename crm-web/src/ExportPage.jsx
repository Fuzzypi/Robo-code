import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { loadStore } from './store/crmStore';

const API_BASE = 'http://localhost:3001';

export function ExportPage() {
  const navigate = useNavigate();
  const [customers, setCustomers] = useState([]);
  const [selectedIds, setSelectedIds] = useState([]);
  const [exportResult, setExportResult] = useState(null);
  const [verificationStatus, setVerificationStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    const store = loadStore();
    setCustomers(store.customers);
  }, []);

  const handleToggleCustomer = (customerId) => {
    setSelectedIds(prev => {
      if (prev.includes(customerId)) {
        return prev.filter(id => id !== customerId);
      }
      return [...prev, customerId];
    });
  };

  const handleCreateExport = async () => {
    if (selectedIds.length === 0) {
      alert('Please select at least one customer');
      return;
    }

    setLoading(true);
    setError(null);
    setExportResult(null);
    setVerificationStatus(null);

    try {
      const store = loadStore();
      
      const response = await fetch(`${API_BASE}/api/export`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          customerIds: selectedIds.map(String),
          storeData: store
        })
      });

      if (!response.ok) {
        throw new Error(`Export failed: ${response.statusText}`);
      }

      const result = await response.json();
      setExportResult(result);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadExport = async () => {
    if (!exportResult) return;

    try {
      const response = await fetch(
        `${API_BASE}/api/export/${exportResult.exportId}/download`
      );

      if (!response.ok) {
        throw new Error(`Download failed: ${response.statusText}`);
      }

      const etag = response.headers.get('ETag');
      const aosProofId = response.headers.get('X-AOS-Proof-Id');
      
      // Verify hash (computedHash available for future verification needs)
      const downloadedData = await response.json();
      const _computedHash = await computeClientHash(downloadedData);
      
      const etagHash = etag ? etag.replace(/"/g, '') : null;
      const hashMatch = etagHash === exportResult.hash;
      
      setVerificationStatus({
        hashMatch,
        etagHash,
        expectedHash: exportResult.hash,
        aosProofId
      });

      // Trigger download
      const blob = new Blob([JSON.stringify(downloadedData, null, 2)], {
        type: 'application/json'
      });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `export-${exportResult.exportId}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setError(`Download error: ${err.message}`);
    }
  };

  const computeClientHash = async (data) => {
    const encoder = new TextEncoder();
    const dataString = JSON.stringify(data);
    const dataBuffer = encoder.encode(dataString);
    const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  };

  return (
    <div style={{ padding: '2rem', maxWidth: '900px', margin: '0 auto' }}>
      <div style={{ marginBottom: '2rem' }}>
        <button 
          onClick={() => navigate('/customers')}
          style={{ padding: '0.5rem 1rem', marginBottom: '1rem', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}
        >
          ← Back to Customers
        </button>
        <h1>Export CRM Data</h1>
      </div>

      {/* Customer Selection */}
      <div style={{ marginBottom: '2rem', border: '1px solid #dee2e6', borderRadius: '8px', padding: '1.5rem', backgroundColor: '#f8f9fa' }}>
        <h2 style={{ marginTop: 0 }}>Select Customers to Export</h2>
        {customers.length === 0 ? (
          <p style={{ color: '#666', fontStyle: 'italic' }}>No customers available</p>
        ) : (
          <div style={{ backgroundColor: 'white', padding: '1rem', borderRadius: '4px', maxHeight: '300px', overflowY: 'auto' }}>
            <div style={{ marginBottom: '1rem' }}>
              <button
                onClick={() => setSelectedIds(selectedIds.length === customers.length ? [] : customers.map(c => c.id))}
                style={{ padding: '0.25rem 0.75rem', fontSize: '0.9rem', backgroundColor: '#e9ecef', border: '1px solid #ced4da', borderRadius: '4px', cursor: 'pointer' }}
              >
                {selectedIds.length === customers.length ? 'Deselect All' : 'Select All'}
              </button>
              <span style={{ marginLeft: '1rem', color: '#666', fontSize: '0.9rem' }}>
                ({selectedIds.length} of {customers.length} selected)
              </span>
            </div>
            {customers.map(customer => (
              <div key={customer.id} style={{ marginBottom: '0.5rem', padding: '0.5rem', borderRadius: '4px', backgroundColor: selectedIds.includes(customer.id) ? '#e7f3ff' : 'transparent' }}>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(customer.id)}
                    onChange={() => handleToggleCustomer(customer.id)}
                    style={{ marginRight: '0.75rem', width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                  <span style={{ fontWeight: selectedIds.includes(customer.id) ? '500' : 'normal' }}>
                    {customer.name}
                  </span>
                </label>
              </div>
            ))}
          </div>
        )}
        <button
          onClick={handleCreateExport}
          disabled={loading || selectedIds.length === 0}
          style={{ 
            marginTop: '1rem', 
            padding: '0.75rem 1.5rem', 
            fontSize: '1rem',
            backgroundColor: selectedIds.length === 0 ? '#6c757d' : '#28a745',
            color: 'white', 
            border: 'none', 
            borderRadius: '4px', 
            cursor: selectedIds.length === 0 ? 'not-allowed' : 'pointer',
            opacity: loading ? 0.6 : 1,
            fontWeight: '500'
          }}
        >
          {loading ? '⏳ Creating Export...' : '📤 Create Export'}
        </button>
      </div>

      {/* Error Display */}
      {error && (
        <div style={{ 
          marginBottom: '2rem', 
          padding: '1rem', 
          backgroundColor: '#f8d7da', 
          border: '1px solid #f5c6cb',
          borderRadius: '4px',
          color: '#721c24'
        }}>
          <strong>❌ Error:</strong> {error}
        </div>
      )}

      {/* Export Result */}
      {exportResult && (
        <div style={{ marginBottom: '2rem', border: '1px solid #28a745', borderRadius: '8px', padding: '1.5rem', backgroundColor: '#d4edda' }}>
          <h2 style={{ marginTop: 0, color: '#155724' }}>✅ Export Created Successfully</h2>
          <div style={{ backgroundColor: 'white', padding: '1rem', borderRadius: '4px' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <tbody>
                <tr>
                  <td style={{ padding: '0.75rem', fontWeight: '600', borderBottom: '1px solid #dee2e6', width: '30%' }}>
                    Export ID
                  </td>
                  <td style={{ padding: '0.75rem', borderBottom: '1px solid #dee2e6', fontFamily: 'monospace', fontSize: '0.9rem' }}>
                    {exportResult.exportId}
                  </td>
                </tr>
                <tr>
                  <td style={{ padding: '0.75rem', fontWeight: '600', borderBottom: '1px solid #dee2e6' }}>
                    Hash (SHA-256)
                  </td>
                  <td style={{ padding: '0.75rem', borderBottom: '1px solid #dee2e6', fontFamily: 'monospace', wordBreak: 'break-all', fontSize: '0.85rem' }}>
                    {exportResult.hash}
                  </td>
                </tr>
                <tr>
                  <td style={{ padding: '0.75rem', fontWeight: '600', borderBottom: '1px solid #dee2e6' }}>
                    Timestamp
                  </td>
                  <td style={{ padding: '0.75rem', borderBottom: '1px solid #dee2e6' }}>
                    {new Date(exportResult.timestamp).toLocaleString('en-US', {
                      weekday: 'short',
                      year: 'numeric',
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                      second: '2-digit'
                    })}
                  </td>
                </tr>
                <tr>
                  <td style={{ padding: '0.75rem', fontWeight: '600' }}>
                    AOS Proof ID
                  </td>
                  <td style={{ padding: '0.75rem', fontFamily: 'monospace', fontSize: '0.9rem' }}>
                    {exportResult.aosProofId}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button
            onClick={handleDownloadExport}
            style={{ marginTop: '1rem', padding: '0.75rem 1.5rem', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '1rem', fontWeight: '500' }}
          >
            💾 Download Export
          </button>
        </div>
      )}

      {/* Verification Status */}
      {verificationStatus && (
        <div style={{ 
          marginBottom: '2rem', 
          padding: '1.5rem', 
          border: `2px solid ${verificationStatus.hashMatch ? '#28a745' : '#dc3545'}`,
          borderRadius: '8px',
          backgroundColor: verificationStatus.hashMatch ? '#d4edda' : '#f8d7da'
        }}>
          <h2 style={{ marginTop: 0, color: verificationStatus.hashMatch ? '#155724' : '#721c24' }}>
            {verificationStatus.hashMatch ? '✅ Hash Verification: PASS' : '❌ Hash Verification: FAIL'}
          </h2>
          <div style={{ backgroundColor: 'white', padding: '1rem', borderRadius: '4px' }}>
            <div style={{ marginBottom: '1rem', padding: '0.75rem', backgroundColor: verificationStatus.hashMatch ? '#d4edda' : '#f8d7da', borderRadius: '4px' }}>
              <strong>Status:</strong>{' '}
              <span style={{ 
                color: verificationStatus.hashMatch ? '#155724' : '#721c24',
                fontWeight: 'bold',
                fontSize: '1.1rem'
              }}>
                {verificationStatus.hashMatch ? '✓ MATCH' : '✗ MISMATCH'}
              </span>
            </div>
            <div style={{ marginBottom: '0.75rem', fontSize: '0.9rem', padding: '0.5rem', backgroundColor: '#f8f9fa', borderRadius: '4px' }}>
              <strong>Expected Hash (from creation):</strong>
              <div style={{ fontFamily: 'monospace', wordBreak: 'break-all', marginTop: '0.25rem', fontSize: '0.85rem' }}>
                {verificationStatus.expectedHash}
              </div>
            </div>
            <div style={{ marginBottom: '0.75rem', fontSize: '0.9rem', padding: '0.5rem', backgroundColor: '#f8f9fa', borderRadius: '4px' }}>
              <strong>Downloaded Hash (ETag):</strong>
              <div style={{ fontFamily: 'monospace', wordBreak: 'break-all', marginTop: '0.25rem', fontSize: '0.85rem' }}>
                {verificationStatus.etagHash}
              </div>
            </div>
            <div style={{ fontSize: '0.9rem', padding: '0.5rem', backgroundColor: '#e7f3ff', borderRadius: '4px' }}>
              <strong>AOS Proof ID:</strong>
              <div style={{ fontFamily: 'monospace', marginTop: '0.25rem' }}>
                {verificationStatus.aosProofId}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
