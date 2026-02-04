import { Link } from 'react-router-dom';
import { useState } from 'react';
import { loadStore, getCustomers } from './store/crmStore';

export function CustomersPage() {
  const [customers] = useState(() => {
    // Initialize state from store on first render
    const store = loadStore();
    return getCustomers(store);
  });

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Customers</h1>
      <div style={{ marginBottom: '1rem' }}>
        <Link to="/export">
          <button>Export Data</button>
        </Link>
      </div>
      <ul>
        {customers.map(customer => (
          <li key={customer.id}>
            <Link to={`/customers/${customer.id}`}>{customer.name}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
