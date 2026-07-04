import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import type { MetalRatesStatus, MetalRatesSyncResult } from '../api';

function formatIst(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
}

function formatInr(value: number | null | undefined): string {
  if (value == null) return '—';
  return `₹${value.toLocaleString('en-IN', { maximumFractionDigits: 2 })}/g`;
}

function formatSilver(value: number | null | undefined): string {
  if (value == null) return '—';
  return `₹${value.toLocaleString('en-IN', { maximumFractionDigits: 0 })}/kg`;
}

export default function Dashboard() {
  const [status, setStatus] = useState<MetalRatesStatus | null>(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [syncing, setSyncing] = useState(false);

  const loadStatus = useCallback(() => {
    api
      .getMetalRatesStatus()
      .then(setStatus)
      .catch((e) => setError(String(e)));
  }, []);

  useEffect(() => {
    loadStatus();
  }, [loadStatus]);

  async function onSync() {
    setSyncing(true);
    setError('');
    setMessage('');
    try {
      const result: MetalRatesSyncResult = await api.syncMetalRates();
      setMessage(
        `Retail rates synced for ${result.rate_date}: 22K ${formatInr(result.gold_22k_per_gram)}, ` +
          `24K ${formatInr(result.gold_24k_per_gram)}, Silver ${formatSilver(result.silver_kg)}.`,
      );
      loadStatus();
    } catch (err) {
      setError(String(err));
    } finally {
      setSyncing(false);
    }
  }

  return (
    <div>
      <h2>Dashboard</h2>

      <div className="card dashboard-card">
        <h3>Gold &amp; Silver rates (retail)</h3>
        <p className="muted">
          Synced from <strong>Goodreturns</strong> &amp; <strong>LiveChennai</strong> — same sources
          as consumer gold websites (~9:30 AM IST). Auto-sync at 10:00, 12:35, and 18:35 IST, or
          refresh manually below.
        </p>

        {status && (
          <dl className="rate-grid">
            <div>
              <dt>Rate date</dt>
              <dd>{status.rate_date ?? '—'}</dd>
            </div>
            <div>
              <dt>22K gold</dt>
              <dd>{formatInr(status.gold_22k_per_gram)}</dd>
            </div>
            <div>
              <dt>24K gold</dt>
              <dd>{formatInr(status.gold_24k_per_gram)}</dd>
            </div>
            <div>
              <dt>Silver</dt>
              <dd>{formatSilver(status.silver_kg)}</dd>
            </div>
            <div>
              <dt>Last sync</dt>
              <dd>{formatIst(status.fetched_at)} IST</dd>
            </div>
            <div>
              <dt>History</dt>
              <dd>{status.daily_history_days ?? 0} days stored</dd>
            </div>
          </dl>
        )}

        <div className="dashboard-actions">
          <button type="button" onClick={onSync} disabled={syncing}>
            {syncing ? 'Syncing retail rates…' : 'Refresh gold & silver rates'}
          </button>
          <button type="button" className="secondary" onClick={loadStatus} disabled={syncing}>
            Reload status
          </button>
        </div>

        {message && <p className="success">{message}</p>}
        {error && <p className="error">{error}</p>}
      </div>

      <div className="card dashboard-links">
        <h3>Quick links</h3>
        <ul>
          <li>
            <Link to="/daily">Daily calendar entries</Link>
          </li>
          <li>
            <Link to="/stories">Status stories</Link>
          </li>
        </ul>
      </div>
    </div>
  );
}
