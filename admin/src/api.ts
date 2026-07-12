import { clearAuthToken, getAuthToken, setAuthToken } from './auth';

const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://localhost:4000/api/v1';

function authHeaders(): Record<string, string> {
  const token = getAuthToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function handleUnauthorized(): never {
  clearAuthToken();
  if (!window.location.pathname.startsWith('/login')) {
    window.location.href = '/login';
  }
  throw new Error('Session expired — please sign in again');
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...authHeaders(), ...options?.headers },
    ...options,
  });
  if (res.status === 401) {
    handleUnauthorized();
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.json() as Promise<T>;
}

async function authFetch(path: string, options?: RequestInit): Promise<Response> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: { ...authHeaders(), ...options?.headers },
  });
  if (res.status === 401) {
    handleUnauthorized();
  }
  return res;
}

export interface StatusStory {
  id: string;
  image_url: string;
  title: string;
  caption: string;
  created_at: string;
}

export interface BookCategory {
  id: string;
  name: string;
  sort_order: number;
  book_count: number;
  created_at: string;
}

export interface LibraryBook {
  id: string;
  category_id: string;
  title: string;
  author: string;
  pdf_url: string;
  preview_url: string | null;
  file_size: number;
  sort_order: number;
  created_at: string;
}

export interface PostBlock {
  type: 'text' | 'image';
  value?: string;
  url?: string;
}

export interface Post {
  id: string;
  title: string;
  content: string;
  image_url: string;
  push_sent: boolean;
  created_at: string;
  blocks?: PostBlock[];
}

export interface IndruPush {
  id: string;
  title: string;
  body: string;
  image_url: string | null;
  push_sent: boolean;
  created_at: string;
}

export type RaasiPalanPeriod = 'today' | 'weekly' | 'monthly' | 'yearly';

export interface RaasiPalanSignIn {
  general_ta: string;
  nakshatra_palan_ta: string;
  balam_ta: string;
  kavanam_ta: string;
  ninaivu_ta: string;
  lucky_numbers_ta: string;
  lucky_colors_ta: string;
  deity_ta: string;
  career_ta: string;
  business_ta: string;
  family_ta: string;
  income_ta: string;
  arts_ta: string;
  investments_ta: string;
  jyotish_view_ta: string;
  cautions_ta: string;
  special_ta: string;
  lucky_days_ta: string;
  chandrashtamam_ta: string;
  remedy_ta: string;
  graham_sancharam_ta: string;
}

export interface RaasiPalanSignBulkItem extends RaasiPalanSignIn {
  sign_index: number;
}

export interface RaasiPalanSign extends RaasiPalanSignIn {
  period: string;
  period_label: string;
  current_label: string;
  updated_at: string | null;
  sign_index: number;
  sign_ta: string;
}

export interface RaasiPalanPeriodData {
  period: string;
  period_label: string;
  current_label: string;
  updated_at: string | null;
  signs: RaasiPalanSign[];
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
  login: async (password: string) => {
    const res = await fetch(`${API_BASE}/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password }),
    });
    if (!res.ok) {
      const text = await res.text();
      let message = text || res.statusText;
      try {
        const parsed = JSON.parse(text) as { detail?: string };
        if (parsed.detail) message = parsed.detail;
      } catch {
        /* use raw text */
      }
      throw new Error(message);
    }
    const data = (await res.json()) as { token: string };
    setAuthToken(data.token);
  },
  logout: () => {
    clearAuthToken();
  },
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
    const res = await authFetch('/admin/status-stories', {
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
  listBookCategories: () => request<BookCategory[]>('/admin/book-categories'),
  createBookCategory: (name: string) =>
    request<BookCategory>('/admin/book-categories', {
      method: 'POST',
      body: JSON.stringify({ name }),
    }),
  deleteBookCategory: (id: string) =>
    request<{ ok: boolean }>(`/admin/book-categories/${id}`, { method: 'DELETE' }),
  listBooks: (categoryId?: string) =>
    request<LibraryBook[]>(
      `/admin/books${categoryId ? `?category_id=${encodeURIComponent(categoryId)}` : ''}`,
    ),
  uploadBook: async (params: {
    file: File;
    categoryId: string;
    title?: string;
    author?: string;
    preview?: File | null;
  }) => {
    const form = new FormData();
    form.append('file', params.file);
    form.append('category_id', params.categoryId);
    form.append('title', params.title ?? '');
    form.append('author', params.author ?? '');
    if (params.preview) {
      form.append('preview', params.preview);
    }
    const res = await authFetch('/admin/books', {
      method: 'POST',
      body: form,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    return res.json() as Promise<LibraryBook>;
  },
  deleteBook: (id: string) => request<{ ok: boolean }>(`/admin/books/${id}`, { method: 'DELETE' }),
  getMetalRatesStatus: () => request<MetalRatesStatus>('/admin/metal-rates/status'),
  syncMetalRates: () =>
    request<MetalRatesSyncResult>('/admin/metal-rates/sync', { method: 'POST' }),
  listPosts: () => request<Post[]>('/admin/posts'),
  uploadPostMedia: async (file: File) => {
    const form = new FormData();
    form.append('file', file);
    const res = await authFetch('/admin/post-media', {
      method: 'POST',
      body: form,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    return res.json() as Promise<{ filename: string; image_url: string }>;
  },
  createPost: async (params: {
    title: string;
    blocks: { type: string; value?: string; filename?: string }[];
    cover?: File | null;
    sendPush?: boolean;
  }) => {
    const form = new FormData();
    form.append('title', params.title);
    form.append('blocks', JSON.stringify(params.blocks));
    form.append('send_push', params.sendPush ? 'true' : 'false');
    if (params.cover) form.append('file', params.cover);
    const res = await authFetch('/admin/posts', {
      method: 'POST',
      body: form,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    return res.json() as Promise<Post>;
  },
  pushPost: (id: string) => request<Post>(`/admin/posts/${id}/push`, { method: 'POST' }),
  deletePost: (id: string) => request<{ ok: boolean }>(`/admin/posts/${id}`, { method: 'DELETE' }),
  listIndruPushes: () => request<IndruPush[]>('/admin/indru/pushes'),
  createIndruPush: async (params: {
    file?: File | null;
    title: string;
    body?: string;
    sendPush?: boolean;
  }) => {
    const form = new FormData();
    if (params.file) form.append('file', params.file);
    form.append('title', params.title);
    form.append('body', params.body ?? '');
    form.append('send_push', params.sendPush ? 'true' : 'false');
    const res = await authFetch('/admin/indru/pushes', {
      method: 'POST',
      body: form,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    return res.json() as Promise<IndruPush>;
  },
  sendIndruPush: (id: string) =>
    request<IndruPush>(`/admin/indru/pushes/${id}/send`, { method: 'POST' }),
  deleteIndruPush: (id: string) =>
    request<{ ok: boolean }>(`/admin/indru/pushes/${id}`, { method: 'DELETE' }),

  getRaasiPalanPeriod: (period: RaasiPalanPeriod) =>
    request<RaasiPalanPeriodData>(`/admin/raasi-palan/${period}`),
  getRaasiPalanSign: (period: RaasiPalanPeriod, signIndex: number) =>
    request<RaasiPalanSign>(`/admin/raasi-palan/${period}/${signIndex}`),
  saveRaasiPalanSign: (
    period: RaasiPalanPeriod,
    signIndex: number,
    body: RaasiPalanSignIn,
  ) =>
    request<RaasiPalanSign>(`/admin/raasi-palan/${period}/${signIndex}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    }),
  saveRaasiPalanPeriod: (period: RaasiPalanPeriod, body: { signs: RaasiPalanSignBulkItem[] }) =>
    request<RaasiPalanPeriodData>(`/admin/raasi-palan/${period}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    }),
};
