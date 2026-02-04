import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { LoginPage } from './LoginPage';
import { CustomersPage } from './CustomersPage';
import { CustomerDetailPage } from './CustomerDetailPage';
import { RequireAuth } from './RequireAuth';
import { getToken } from './auth';
import './App.css';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/customers"
          element={
            <RequireAuth>
              <CustomersPage />
            </RequireAuth>
          }
        />
        <Route
          path="/customers/:id"
          element={
            <RequireAuth>
              <CustomerDetailPage />
            </RequireAuth>
          }
        />
        <Route
          path="/"
          element={
            getToken() ? <Navigate to="/customers" replace /> : <Navigate to="/login" replace />
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
