import { useParams, useNavigate } from 'react-router-dom';
import { clearToken } from './auth';

export function CustomerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const handleLogout = () => {
    clearToken();
    navigate('/login');
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Customer Detail</h1>
      <p>Customer ID: {id}</p>
      <button onClick={handleLogout}>Logout</button>
    </div>
  );
}
