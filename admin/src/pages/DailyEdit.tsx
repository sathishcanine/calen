import { useEffect, useState, type FormEvent } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../api';
import type { DailyCalendar } from '../api';

const empty: DailyCalendar = {
  city_id: 'chennai',
  gregorian_date: '',
  month_label_ta: '',
  gregorian_display: '',
  banner_line_ta: '',
  events_ta: '',
  quote_ta: '',
  birthdays_ta: '',
  note_ta: '',
  subtitle_line1_ta: '',
  subtitle_line2_ta: '',
  nalla_neram: [],
  gowri_nalla_neram: [],
  panchangam: [],
  horoscope: [],
};

export default function DailyEdit() {
  const { cityId = 'chennai', date = '' } = useParams();
  const navigate = useNavigate();
  const [form, setForm] = useState<DailyCalendar>(empty);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!date) return;
    api
      .getDaily(cityId, date)
      .then(setForm)
      .catch((e) => setError(String(e)));
  }, [cityId, date]);

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setMessage('');
    setError('');
    try {
      await api.saveDaily(cityId, date, form);
      setMessage('Saved successfully.');
    } catch (err) {
      setError(String(err));
    }
  };

  const set = (key: keyof DailyCalendar, value: string) =>
    setForm((f) => ({ ...f, [key]: value }));

  return (
    <div>
      <h2>Edit daily — {date}</h2>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}
      <form className="card" onSubmit={onSubmit}>
        <div className="row">
          <div>
            <label>Banner (Tamil)</label>
            <input value={form.banner_line_ta} onChange={(e) => set('banner_line_ta', e.target.value)} />
          </div>
          <div>
            <label>Gregorian display</label>
            <input value={form.gregorian_display} onChange={(e) => set('gregorian_display', e.target.value)} />
          </div>
        </div>
        <label>Month label</label>
        <input value={form.month_label_ta} onChange={(e) => set('month_label_ta', e.target.value)} />
        <label>Subtitle line 1</label>
        <input value={form.subtitle_line1_ta} onChange={(e) => set('subtitle_line1_ta', e.target.value)} />
        <label>Subtitle line 2</label>
        <input value={form.subtitle_line2_ta} onChange={(e) => set('subtitle_line2_ta', e.target.value)} />
        <label>Events</label>
        <textarea value={form.events_ta} onChange={(e) => set('events_ta', e.target.value)} />
        <label>Quote (பொன்மொழி)</label>
        <textarea value={form.quote_ta} onChange={(e) => set('quote_ta', e.target.value)} />
        <label>Birthdays</label>
        <textarea value={form.birthdays_ta} onChange={(e) => set('birthdays_ta', e.target.value)} />
        <label>Note</label>
        <textarea value={form.note_ta} onChange={(e) => set('note_ta', e.target.value)} />
        <button type="submit">Save</button>
        <button type="button" className="secondary" style={{ marginLeft: 8 }} onClick={() => navigate('/')}>
          Back
        </button>
      </form>
    </div>
  );
}
