const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://localhost:4000/api/v1';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.json() as Promise<T>;
}

export interface DailyCalendar {
  city_id: string;
  gregorian_date: string;
  month_label_ta: string;
  gregorian_display: string;
  banner_line_ta: string;
  events_ta: string;
  quote_ta: string;
  birthdays_ta: string;
  note_ta: string;
  subtitle_line1_ta: string;
  subtitle_line2_ta: string;
  nalla_neram: { period: string; time: string }[];
  gowri_nalla_neram: { period: string; time: string }[];
  panchangam: { label: string; value: string }[];
  horoscope: { sign: string; prediction: string }[];
}

export const api = {
  listDaily: (cityId?: string) =>
    request<DailyCalendar[]>(`/admin/daily${cityId ? `?city_id=${cityId}` : ''}`),
  getDaily: (cityId: string, date: string) =>
    request<DailyCalendar>(`/admin/daily/${cityId}/${date}`),
  saveDaily: (cityId: string, date: string, body: Partial<DailyCalendar>) =>
    request<DailyCalendar>(`/admin/daily/${cityId}/${date}`, {
      method: 'PUT',
      body: JSON.stringify({ city_id: cityId, gregorian_date: date, ...body }),
    }),
  getMonth: (cityId: string, year: number, month: number) =>
    request<Record<string, unknown>>(`/admin/month/${cityId}/${year}/${month}`),
};
