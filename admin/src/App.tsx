import { NavLink, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import './App.css';
import { isAuthenticated } from './auth';
import DailyEdit from './pages/DailyEdit';
import DailyList from './pages/DailyList';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Stories from './pages/Stories';
import Books from './pages/Books';
import Posts from './pages/Posts';
import IndruPushPage from './pages/IndruPush';
import { api } from './api';

function RequireAuth({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  if (!isAuthenticated()) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }
  return children;
}

function AdminLayout() {
  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>தமிழர் உலகம் — Admin</h1>
        <NavLink to="/" end>
          Dashboard
        </NavLink>
        <NavLink to="/daily">Daily entries</NavLink>
        <NavLink to="/stories">Status stories</NavLink>
        <NavLink to="/books">Books library</NavLink>
        <NavLink to="/koodiya-thagaval-post">கூடிய தகவல்</NavLink>
        <NavLink to="/indru-push">இன்று push</NavLink>
        <button
          type="button"
          className="sidebar-logout"
          onClick={() => {
            api.logout();
            window.location.href = '/login';
          }}
        >
          Sign out
        </button>
      </aside>
      <main className="main">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/daily" element={<DailyList />} />
          <Route path="/daily/:cityId/:date" element={<DailyEdit />} />
          <Route path="/stories" element={<Stories />} />
          <Route path="/books" element={<Books />} />
          <Route path="/koodiya-thagaval-post" element={<Posts />} />
          <Route path="/news-post" element={<Navigate to="/koodiya-thagaval-post" replace />} />
          <Route path="/posts" element={<Navigate to="/koodiya-thagaval-post" replace />} />
          <Route path="/indru-push" element={<IndruPushPage />} />
        </Routes>
      </main>
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/*"
        element={
          <RequireAuth>
            <AdminLayout />
          </RequireAuth>
        }
      />
    </Routes>
  );
}
