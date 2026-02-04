import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { LoginPage } from './LoginPage';
import { CustomersPage } from './CustomersPage';
import { CustomerDetailPage } from './CustomerDetailPage';
import { ExportPage } from './ExportPage';
import { RequireAuth } from './RequireAuth';
import { ErrorBoundary } from './ErrorBoundary';
import { getToken } from './auth';
import './App.css';

function App() {
  return (
    <ErrorBoundary>
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
            path="/export"
            element={
              <RequireAuth>
                <ErrorBoundary>
                  <ExportPage />
                </ErrorBoundary>
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
    </ErrorBoundary>
  );
}

export default App;
