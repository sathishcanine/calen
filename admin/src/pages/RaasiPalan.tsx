import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { api, type RaasiPalanPeriod, type RaasiPalanSign } from '../api';

const PERIODS: { id: RaasiPalanPeriod; label: string; hint: string }[] = [
  { id: 'today', label: 'இன்று', hint: 'Current date' },
  { id: 'weekly', label: 'வாரம்', hint: 'Current week' },
  { id: 'monthly', label: 'மாதம்', hint: 'Current month' },
  { id: 'yearly', label: 'வருடம்', hint: 'Current year' },
];

const EMPTY_SIGN = (index: number, name: string): RaasiPalanSign => ({
  period: 'today',
  period_label: '',
  current_label: '',
  updated_at: null,
  sign_index: index,
  sign_ta: name,
  general_ta: '',
  nakshatra_palan_ta: '',
  balam_ta: '',
  kavanam_ta: '',
  ninaivu_ta: '',
  lucky_numbers_ta: '',
  lucky_colors_ta: '',
  deity_ta: '',
  career_ta: '',
  business_ta: '',
  family_ta: '',
  income_ta: '',
  arts_ta: '',
  investments_ta: '',
  jyotish_view_ta: '',
  cautions_ta: '',
  special_ta: '',
  lucky_days_ta: '',
  chandrashtamam_ta: '',
  remedy_ta: '',
  graham_sancharam_ta: '',
});

const SIGN_NAMES = [
  'மேஷம்',
  'ரிஷபம்',
  'மிதுனம்',
  'கடகம்',
  'சிம்மம்',
  'கன்னி',
  'துலாம்',
  'விருச்சிகம்',
  'தனுசு',
  'மகரம்',
  'கும்பம்',
  'மீனம்',
];

function isFilled(s: RaasiPalanSign, period: RaasiPalanPeriod): boolean {
  if (period === 'yearly') {
    return Boolean(
      s.graham_sancharam_ta.trim() ||
        s.general_ta.trim() ||
        s.nakshatra_palan_ta.trim() ||
        s.special_ta.trim() ||
        s.cautions_ta.trim(),
    );
  }
  return s.general_ta.trim().length > 0;
}

function payloadFrom(s: RaasiPalanSign, period: RaasiPalanPeriod) {
  const base = EMPTY_SIGN(s.sign_index, s.sign_ta);
  if (period === 'yearly') {
    return {
      ...base,
      graham_sancharam_ta: s.graham_sancharam_ta,
      general_ta: s.general_ta,
      nakshatra_palan_ta: s.nakshatra_palan_ta,
      special_ta: s.special_ta,
      cautions_ta: s.cautions_ta,
    };
  }
  return {
    ...base,
    general_ta: s.general_ta,
  };
}

export default function RaasiPalan() {
  const [period, setPeriod] = useState<RaasiPalanPeriod>('today');
  const [signs, setSigns] = useState<RaasiPalanSign[]>(
    SIGN_NAMES.map((name, i) => EMPTY_SIGN(i, name)),
  );
  const [activeIndex, setActiveIndex] = useState(0);
  const [periodLabel, setPeriodLabel] = useState('');
  const [currentLabel, setCurrentLabel] = useState('');
  const [updatedAt, setUpdatedAt] = useState<string | null>(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const active = signs[activeIndex] ?? EMPTY_SIGN(0, SIGN_NAMES[0]);
  const periodMeta = useMemo(
    () => PERIODS.find((p) => p.id === period)!,
    [period],
  );
  const isYearly = period === 'yearly';

  function load(nextPeriod: RaasiPalanPeriod) {
    setLoading(true);
    setError('');
    setMessage('');
    api
      .getRaasiPalanPeriod(nextPeriod)
      .then((data) => {
        setPeriodLabel(data.period_label);
        setCurrentLabel(data.current_label);
        setUpdatedAt(data.updated_at);
        const byIndex = new Map(data.signs.map((s) => [s.sign_index, s]));
        setSigns(
          SIGN_NAMES.map((name, i) => ({
            ...EMPTY_SIGN(i, name),
            ...(byIndex.get(i) ?? {}),
          })),
        );
      })
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load(period);
  }, [period]);

  function updateActive(patch: Partial<RaasiPalanSign>) {
    setSigns((prev) =>
      prev.map((s, i) => (i === activeIndex ? { ...s, ...patch } : s)),
    );
  }

  async function saveActive(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError('');
    setMessage('');
    try {
      const saved = await api.saveRaasiPalanSign(
        period,
        activeIndex,
        payloadFrom(active, period),
      );
      setSigns((prev) =>
        prev.map((s, i) => (i === activeIndex ? { ...s, ...saved } : s)),
      );
      setPeriodLabel(saved.period_label);
      setCurrentLabel(saved.current_label);
      setUpdatedAt(saved.updated_at);
      setMessage(`${active.sign_ta} — ${periodMeta.label} சேமிக்கப்பட்டது`);
    } catch (err) {
      setError(String(err));
    } finally {
      setSaving(false);
    }
  }

  async function saveAll() {
    if (!confirm(`எல்லா 12 ராசிகளையும் ${periodMeta.label}-க்கு சேமிக்கவா?`)) {
      return;
    }
    setSaving(true);
    setError('');
    setMessage('');
    try {
      const data = await api.saveRaasiPalanPeriod(period, {
        signs: signs.map((s) => ({
          ...payloadFrom(s, period),
        })),
      });
      setPeriodLabel(data.period_label);
      setCurrentLabel(data.current_label);
      setUpdatedAt(data.updated_at);
      const byIndex = new Map(data.signs.map((s) => [s.sign_index, s]));
      setSigns(
        SIGN_NAMES.map((name, i) => ({
          ...EMPTY_SIGN(i, name),
          ...(byIndex.get(i) ?? {}),
        })),
      );
      setMessage(`எல்லா 12 ராசிகளும் ${periodMeta.label}-க்கு சேமிக்கப்பட்டன`);
    } catch (err) {
      setError(String(err));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <h2 style={{ marginTop: 0 }}>ராசி பலன்</h2>
      <p style={{ color: '#546e7a', marginTop: 0 }}>
        Use <code>#சொல்#</code> to bold a word in the app. Yearly has 5 fields;
        other periods use one பொது பலன் box.
      </p>

      <div className="card" style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {PERIODS.map((p) => (
            <button
              key={p.id}
              type="button"
              className={period === p.id ? undefined : 'secondary'}
              onClick={() => {
                setPeriod(p.id);
                setActiveIndex(0);
              }}
            >
              {p.label}
              <span style={{ opacity: 0.75, marginLeft: 6, fontSize: 12 }}>
                ({p.hint})
              </span>
            </button>
          ))}
        </div>
        <div style={{ marginTop: 12, fontSize: 14, color: '#455a64' }}>
          <strong>{periodMeta.label}</strong>
          {' · '}
          Saved for: <code>{periodLabel || '—'}</code>
          {' · '}
          Current: <code>{currentLabel || '—'}</code>
          {updatedAt ? ` · Updated: ${updatedAt}` : null}
        </div>
      </div>

      {error ? <p className="error">{error}</p> : null}
      {message ? <p className="success">{message}</p> : null}
      {loading ? <p>Loading…</p> : null}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '220px 1fr',
          gap: 16,
          alignItems: 'start',
        }}
      >
        <div className="card">
          <h3 style={{ marginTop: 0 }}>12 ராசிகள்</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {signs.map((s, i) => (
              <button
                key={s.sign_index}
                type="button"
                className={i === activeIndex ? undefined : 'secondary'}
                style={{ textAlign: 'left' }}
                onClick={() => setActiveIndex(i)}
              >
                {s.sign_index + 1}. {s.sign_ta}
                {isFilled(s, period) ? ' ✓' : ''}
              </button>
            ))}
          </div>
          <button
            type="button"
            className="secondary"
            style={{ marginTop: 12, width: '100%' }}
            disabled={saving}
            onClick={saveAll}
          >
            Save all 12
          </button>
        </div>

        <form className="card" onSubmit={saveActive}>
          <h3 style={{ marginTop: 0 }}>
            {active.sign_ta} — {periodMeta.label}
          </h3>

          {isYearly ? (
            <>
              <label>
                கிரக சஞ்சார பலன்கள்
                <textarea
                  rows={6}
                  value={active.graham_sancharam_ta}
                  onChange={(e) =>
                    updateActive({ graham_sancharam_ta: e.target.value })
                  }
                />
              </label>
              <label style={{ marginTop: 12, display: 'block' }}>
                பொதுப் பலன்கள்
                <textarea
                  rows={6}
                  value={active.general_ta}
                  onChange={(e) => updateActive({ general_ta: e.target.value })}
                />
              </label>
              <label style={{ marginTop: 12, display: 'block' }}>
                ⭐ நட்சத்திர பலன்கள்
                <textarea
                  rows={6}
                  value={active.nakshatra_palan_ta}
                  onChange={(e) =>
                    updateActive({ nakshatra_palan_ta: e.target.value })
                  }
                />
              </label>
              <label style={{ marginTop: 12, display: 'block' }}>
                🌟 இந்த ஆண்டின் சிறப்புகள்
                <textarea
                  rows={5}
                  value={active.special_ta}
                  onChange={(e) => updateActive({ special_ta: e.target.value })}
                />
              </label>
              <label style={{ marginTop: 12, display: 'block' }}>
                ⚠️ கவனமாக இருக்க வேண்டியவை
                <textarea
                  rows={5}
                  value={active.cautions_ta}
                  onChange={(e) => updateActive({ cautions_ta: e.target.value })}
                />
              </label>
            </>
          ) : (
            <label>
              பொது பலன் (full text — paste everything here)
              <textarea
                rows={22}
                value={active.general_ta}
                onChange={(e) => updateActive({ general_ta: e.target.value })}
                placeholder={`${active.sign_ta} ராசி அன்பர்களே!

முழு பலனையும் இங்கே ஒட்டவும்…
Bold: #முக்கியம்#`}
              />
            </label>
          )}

          <div style={{ marginTop: 16, display: 'flex', gap: 10 }}>
            <button type="submit" disabled={saving}>
              {saving ? 'Saving…' : `Save ${active.sign_ta}`}
            </button>
            <button
              type="button"
              className="secondary"
              disabled={activeIndex >= 11}
              onClick={() => setActiveIndex((i) => Math.min(11, i + 1))}
            >
              Next raasi →
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
