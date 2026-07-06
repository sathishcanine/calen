import { NavLink, Route, Routes } from 'react-router-dom';
import './App.css';
import DailyEdit from './pages/DailyEdit';
import DailyList from './pages/DailyList';
import Dashboard from './pages/Dashboard';
import Stories from './pages/Stories';
import Books from './pages/Books';
import Posts from './pages/Posts';
import IndruPushPage from './pages/IndruPush';

export default function App() {
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
        <NavLink to="/posts">Posts</NavLink>
        <NavLink to="/indru-push">இன்று push</NavLink>
      </aside>
      <main className="main">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/daily" element={<DailyList />} />
          <Route path="/daily/:cityId/:date" element={<DailyEdit />} />
          <Route path="/stories" element={<Stories />} />
          <Route path="/books" element={<Books />} />
          <Route path="/posts" element={<Posts />} />
          <Route path="/indru-push" element={<IndruPushPage />} />
        </Routes>
      </main>
    </div>
  );
}
