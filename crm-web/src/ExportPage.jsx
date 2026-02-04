import { useState, useEffect } from 'react';
import { loadStore } from './store/crmStore';

const API_BASE = 'http://localhost:3001';

export function ExportPage() {
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
      
      // Verify hash
      const downloadedData = await response.json();
      const computedHash = await computeClientHash(downloadedData);
      
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
    <div style={{ padding: '2rem', maxWidth: '800px' }}>
      <h1>Export CRM Data</h1>

      {/* Customer Selection */}
      <div style={{ marginBottom: '2rem', border: '1px solid #ccc', padding: '1rem' }}>
        <h2>Select Customers</h2>
        {customers.length === 0 ? (
          <p>No customers available</p>
        ) : (
          <div>
            {customers.map(customer => (
              <div key={customer.id} style={{ marginBottom: '0.5rem' }}>
                <label>
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(customer.id)}
                    onChange={() => handleToggleCustomer(customer.id)}
                  />
                  {' '}
                  {customer.name}
                </label>
              </div>
            ))}
          </div>
        )}
        <button
          onClick={handleCreateExport}
          disabled={loading || selectedIds.length === 0}
          style={{ marginTop: '1rem', padding: '0.5rem 1rem' }}
        >
          {loading ? 'Creating Export...' : 'Create Export'}
        </button>
      </div>

      {/* Error Display */}
      {error && (
        <div style={{ 
          marginBottom: '2rem', 
          padding: '1rem', 
          backgroundColor: '#fee', 
          border: '1px solid #c00',
          color: '#c00'
        }}>
          <strong>Error:</strong> {error}
        </div>
      )}

      {/* Export Result */}
      {exportResult && (
        <div style={{ marginBottom: '2rem', border: '1px solid #ccc', padding: '1rem' }}>
          <h2>Export Proof</h2>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <tbody>
              <tr>
                <td style={{ padding: '0.5rem', fontWeight: 'bold', borderBottom: '1px solid #ccc' }}>
                  Export ID
                </td>
                <td style={{ padding: '0.5rem', borderBottom: '1px solid #ccc', fontFamily: 'monospace' }}>
                  {exportResult.exportId}
                </td>
              </tr>
              <tr>
                <td style={{ padding: '0.5rem', fontWeight: 'bold', borderBottom: '1px solid #ccc' }}>
                  Hash
                </td>
                <td style={{ padding: '0.5rem', borderBottom: '1px solid #ccc', fontFamily: 'monospace', wordBreak: 'break-all' }}>
                  {exportResult.hash}
                </td>
              </tr>
              <tr>
                <td style={{ padding: '0.5rem', fontWeight: 'bold', borderBottom: '1px solid #ccc' }}>
                  Timestamp
                </td>
                <td style={{ padding: '0.5rem', borderBottom: '1px solid #ccc' }}>
                  {new Date(exportResult.timestamp).toLocaleString()}
                </td>
              </tr>
              <tr>
                <td style={{ padding: '0.5rem', fontWeight: 'bold' }}>
                  AOS Proof ID
                </td>
                <td style={{ padding: '0.5rem', fontFamily: 'monospace' }}>
                  {exportResult.aosProofId}
                </td>
              </tr>
            </tbody>
          </table>

          <button
            onClick={handleDownloadExport}
            style={{ marginTop: '1rem', padding: '0.5rem 1rem' }}
          >
            Download Export
          </button>
        </div>
      )}

      {/* Verification Status */}
      {verificationStatus && (
        <div style={{ 
          marginBottom: '2rem', 
          padding: '1rem', 
          border: '1px solid #ccc',
          backgroundColor: verificationStatus.hashMatch ? '#efe' : '#fee'
        }}>
          <h2>Hash Verification</h2>
          <div style={{ marginBottom: '0.5rem' }}>
            <strong>Status:</strong>{' '}
            <span style={{ 
              color: verificationStatus.hashMatch ? 'green' : 'red',
              fontWeight: 'bold'
            }}>
              {verificationStatus.hashMatch ? '✓ MATCH' : '✗ MISMATCH'}
            </span>
          </div>
          <div style={{ marginBottom: '0.5rem', fontSize: '0.9rem' }}>
            <strong>Expected Hash:</strong>
            <div style={{ fontFamily: 'monospace', wordBreak: 'break-all' }}>
              {verificationStatus.expectedHash}
            </div>
          </div>
          <div style={{ marginBottom: '0.5rem', fontSize: '0.9rem' }}>
            <strong>Downloaded Hash (ETag):</strong>
            <div style={{ fontFamily: 'monospace', wordBreak: 'break-all' }}>
              {verificationStatus.etagHash}
            </div>
          </div>
          <div style={{ fontSize: '0.9rem' }}>
            <strong>AOS Proof ID:</strong>
            <div style={{ fontFamily: 'monospace' }}>
              {verificationStatus.aosProofId}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
