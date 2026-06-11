import { NavLink, Route, Routes } from 'react-router-dom';
import './App.css';
import DailyEdit from './pages/DailyEdit';
import DailyList from './pages/DailyList';

export default function App() {
  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>தமிழர் உலகம் — Admin</h1>
        <NavLink to="/" end>
          Daily entries
        </NavLink>
      </aside>
      <main className="main">
        <Routes>
          <Route path="/" element={<DailyList />} />
          <Route path="/daily/:cityId/:date" element={<DailyEdit />} />
        </Routes>
      </main>
    </div>
  );
}
