import { Link } from 'react-router-dom';

const CUSTOMERS = [
  { id: 1, name: 'Acme Corp' },
  { id: 2, name: 'Globex Inc' },
  { id: 3, name: 'Initech Ltd' }
];

export function CustomersPage() {
  return (
    <div style={{ padding: '2rem' }}>
      <h1>Customers</h1>
      <ul>
        {CUSTOMERS.map(customer => (
          <li key={customer.id}>
            <Link to={`/customers/${customer.id}`}>{customer.name}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
