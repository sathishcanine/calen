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

export interface StatusStory {
  id: string;
  image_url: string;
  title: string;
  caption: string;
  created_at: string;
}

export interface MetalRatesStatus {
  source: string | null;
  rate_date: string | null;
  gold_22k_per_gram: number | null;
  gold_24k_per_gram: number | null;
  silver_kg: number | null;
  fetched_at: string | null;
  daily_history_days: number;
  cron_schedule_ist: string[];
  rate_source_note: string;
}

export interface MetalRatesSyncResult {
  ok: boolean;
  source: string;
  rate_date: string;
  gold_22k_per_gram: number;
  gold_24k_per_gram: number;
  silver_kg: number;
  fetched_at: string | null;
  daily_history_days: number;
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
  listStatusStories: () => request<StatusStory[]>('/admin/status-stories'),
  uploadStatusStory: async (params: {
    file: File;
    title?: string;
    caption?: string;
  }) => {
    const form = new FormData();
    form.append('file', params.file);
    form.append('title', params.title ?? '');
    form.append('caption', params.caption ?? '');
    const res = await fetch(`${API_BASE}/admin/status-stories`, {
      method: 'POST',
      body: form,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    return res.json() as Promise<StatusStory>;
  },
  deleteStatusStory: (id: string) =>
    request<{ ok: boolean }>(`/admin/status-stories/${id}`, { method: 'DELETE' }),
  getMetalRatesStatus: () => request<MetalRatesStatus>('/admin/metal-rates/status'),
  syncMetalRates: () =>
    request<MetalRatesSyncResult>('/admin/metal-rates/sync', { method: 'POST' }),
};
