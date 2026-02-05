import { Link, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { loadStore, getCustomers } from './store/crmStore';
import { clearToken } from './auth';

export function CustomersPage() {
  const navigate = useNavigate();
  const [customers] = useState(() => {
    const store = loadStore();
    return getCustomers(store);
  });

  const handleLogout = () => {
    clearToken();
    navigate('/login');
  };

  return (
    <div style={{ padding: '2rem', maxWidth: '1000px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1>CRM - Customers</h1>
        <button onClick={handleLogout} style={{ padding: '0.5rem 1rem' }}>
          Logout
        </button>
      </div>

      <div style={{ marginBottom: '2rem' }}>
        <Link to="/export">
          <button style={{ padding: '0.75rem 1.5rem', fontSize: '1rem', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>
            📊 Export Data
          </button>
        </Link>
      </div>

      <div style={{ border: '1px solid #ddd', borderRadius: '4px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #ddd' }}>
              <th style={{ padding: '1rem', textAlign: 'left' }}>Customer Name</th>
              <th style={{ padding: '1rem', textAlign: 'left' }}>Email</th>
              <th style={{ padding: '1rem', textAlign: 'left' }}>Phone</th>
            </tr>
          </thead>
          <tbody>
            {customers.length === 0 ? (
              <tr>
                <td colSpan="3" style={{ padding: '2rem', textAlign: 'center', color: '#666' }}>
                  No customers found
                </td>
              </tr>
            ) : (
              customers.map(customer => (
                <tr key={customer.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: '1rem' }}>
                    <Link 
                      to={`/customers/${customer.id}`}
                      style={{ color: '#007bff', textDecoration: 'none', fontWeight: '500' }}
                    >
                      {customer.name}
                    </Link>
                  </td>
                  <td style={{ padding: '1rem', color: '#666' }}>{customer.email}</td>
                  <td style={{ padding: '1rem', color: '#666' }}>{customer.phone}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: '2rem', color: '#666', fontSize: '0.9rem' }}>
        <p>Total Customers: <strong>{customers.length}</strong></p>
      </div>
    </div>
  );
}
