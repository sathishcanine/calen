import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import type { DailyCalendar } from '../api';

export default function DailyList() {
  const [items, setItems] = useState<DailyCalendar[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .listDaily('chennai')
      .then(setItems)
      .catch((e) => setError(String(e)));
  }, []);

  return (
    <div>
      <h2>Daily calendar entries</h2>
      {error && <p className="error">{error}</p>}
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Banner</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((row) => (
              <tr key={row.gregorian_date}>
                <td>{row.gregorian_date}</td>
                <td>{row.banner_line_ta}</td>
                <td>
                  <Link to={`/daily/chennai/${row.gregorian_date}`}>Edit</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
