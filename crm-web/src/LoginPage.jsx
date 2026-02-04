import { useNavigate } from 'react-router-dom';
import { setToken } from './auth';

export function LoginPage() {
  const navigate = useNavigate();

  const handleLogin = () => {
    setToken('dummy-auth-token');
    navigate('/customers');
  };

  return (
    <div style={{ padding: '2rem', textAlign: 'center' }}>
      <h1>Login</h1>
      <button onClick={handleLogin}>Log in</button>
    </div>
  );
}
