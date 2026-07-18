import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import type {
  DailyMorningPushResult,
  MetalRatesStatus,
  MetalRatesSyncResult,
  RaasiPalanSyncJob,
} from '../api';

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
  const [pushError, setPushError] = useState('');
  const [pushMessage, setPushMessage] = useState('');
  const [sendingPush, setSendingPush] = useState(false);
  const [homeTitle, setHomeTitle] = useState('');
  const [homeBody, setHomeBody] = useState('');
  const [homeFile, setHomeFile] = useState<File | null>(null);
  const [raasiJob, setRaasiJob] = useState<RaasiPalanSyncJob | null>(null);
  const [raasiStarting, setRaasiStarting] = useState(false);
  const [raasiError, setRaasiError] = useState('');

  const loadStatus = useCallback(() => {
    api
      .getMetalRatesStatus()
      .then(setStatus)
      .catch((e) => setError(String(e)));
  }, []);

  useEffect(() => {
    loadStatus();
  }, [loadStatus]);

  const loadRaasiStatus = useCallback(() => {
    api
      .getLatestRaasiPalanSync()
      .then(setRaasiJob)
      .catch((e) => setRaasiError(String(e)));
  }, []);

  useEffect(() => {
    loadRaasiStatus();
  }, [loadRaasiStatus]);

  useEffect(() => {
    const jobId = raasiJob?.job_id;
    if (!jobId || raasiJob.status !== 'running') return;
    const timer = window.setInterval(() => {
      api
        .getRaasiPalanSync(jobId)
        .then(setRaasiJob)
        .catch((e) => setRaasiError(String(e)));
    }, 2500);
    return () => window.clearInterval(timer);
  }, [raasiJob?.job_id, raasiJob?.status]);

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

  async function onSendHomePush(e: FormEvent) {
    e.preventDefault();
    if (!homeTitle.trim()) {
      setPushError('Title is required');
      return;
    }
    setSendingPush(true);
    setPushError('');
    setPushMessage('');
    try {
      const result: DailyMorningPushResult = await api.sendDailyMorningPush({
        title: homeTitle,
        body: homeBody,
        file: homeFile,
      });
      setPushMessage(`Push sent — opens Home: ${result.title}`);
      setHomeFile(null);
    } catch (err) {
      setPushError(String(err));
    } finally {
      setSendingPush(false);
    }
  }

  async function onRaasiSync() {
    if (!confirm('Fetch and update today’s பொதுப் பலன் for all 12 raasis?')) {
      return;
    }
    setRaasiStarting(true);
    setRaasiError('');
    try {
      setRaasiJob(await api.startRaasiPalanSync());
    } catch (err) {
      setRaasiError(String(err));
    } finally {
      setRaasiStarting(false);
    }
  }

  const raasiCompleted =
    raasiJob?.signs.filter((entry) => entry.status === 'success').length ?? 0;
  const raasiFailed =
    raasiJob?.signs.filter((entry) => entry.status === 'failed').length ?? 0;
  const raasiRunning = raasiJob?.status === 'running';

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

      <div className="card dashboard-card">
        <h3>Daily raasi palan automation</h3>
        <p className="muted">
          Fetch AstroSage, rephrase through OpenAI, and update only today’s பொதுப் பலன்.
          Each raasi is saved separately; failures are shown below.
        </p>
        <div className="dashboard-actions">
          <button
            type="button"
            onClick={onRaasiSync}
            disabled={raasiStarting || raasiRunning}
          >
            {raasiStarting
              ? 'Starting…'
              : raasiRunning
                ? `Syncing raasis… ${raasiCompleted}/12`
                : 'Fetch & update all 12 raasis'}
          </button>
          <button
            type="button"
            className="secondary"
            onClick={loadRaasiStatus}
            disabled={raasiStarting}
          >
            Reload status
          </button>
          <Link to="/raasi-palan">Open raasi editor</Link>
        </div>

        {raasiJob && raasiJob.status !== 'idle' ? (
          <ul>
            {raasiJob.signs.map((entry) => (
              <li key={entry.sign_index}>
                {entry.status === 'success'
                  ? '✓'
                  : entry.status === 'failed'
                    ? '✗'
                    : entry.status === 'running'
                      ? '⏳'
                      : '◷'}{' '}
                <strong>{entry.sign_ta}</strong>
                {entry.last_error ? ` — ${entry.last_error}` : ''}
              </li>
            ))}
          </ul>
        ) : null}
        {raasiJob?.status === 'completed' ? (
          <p className="success">All 12 raasis updated successfully.</p>
        ) : null}
        {raasiJob?.status === 'completed_with_errors' ? (
          <p className="error">
            Sync finished: {raasiCompleted} succeeded, {raasiFailed} failed.
          </p>
        ) : null}
        {raasiError ? <p className="error">{raasiError}</p> : null}
      </div>

      <form className="card dashboard-card" onSubmit={onSendHomePush}>
        <h3>Home push notification</h3>
        <p className="muted">
          Write your own title and description, optionally add an image, then send. Tap opens the
          app home screen. Does not affect the automatic 6:30 AM IST push.
        </p>
        <label>Title</label>
        <input
          value={homeTitle}
          onChange={(e) => setHomeTitle(e.target.value)}
          placeholder="Notification title"
          required
        />
        <label>Description (optional)</label>
        <textarea
          value={homeBody}
          onChange={(e) => setHomeBody(e.target.value)}
          placeholder="Short message under the title"
          rows={4}
        />
        <label>Image (optional)</label>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setHomeFile(e.target.files?.[0] ?? null)}
        />
        <div className="dashboard-actions">
          <button type="submit" disabled={sendingPush}>
            {sendingPush ? 'Sending…' : 'Send home push'}
          </button>
        </div>
        {pushMessage && <p className="success">{pushMessage}</p>}
        {pushError && <p className="error">{pushError}</p>}
      </form>

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
