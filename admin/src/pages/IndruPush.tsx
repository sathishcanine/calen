import { useEffect, useState, type FormEvent } from 'react';
import { api } from '../api';
import type { IndruPush } from '../api';

export default function IndruPushPage() {
  const [items, setItems] = useState<IndruPush[]>([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [uploading, setUploading] = useState(false);
  const [title, setTitle] = useState('இன்று — தினசரி தகவல்கள்');
  const [body, setBody] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [sendPush, setSendPush] = useState(true);
  const [pushingId, setPushingId] = useState<string | null>(null);

  const refresh = () => {
    api
      .listIndruPushes()
      .then(setItems)
      .catch((e) => setError(String(e)));
  };

  useEffect(() => {
    refresh();
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!title.trim()) {
      setError('Title is required');
      return;
    }
    setUploading(true);
    setError('');
    setMessage('');
    try {
      const row = await api.createIndruPush({ file, title, body, sendPush });
      setFile(null);
      setBody('');
      setSendPush(true);
      setMessage(
        sendPush
          ? 'இன்று notification sent to app users.'
          : 'Saved (push not sent).',
      );
      refresh();
      if (sendPush && !row.push_sent) {
        setMessage('Saved, but push failed — check FIREBASE_CREDENTIALS_PATH on the API.');
      }
    } catch (err) {
      setError(String(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete this notification?')) return;
    setError('');
    try {
      await api.deleteIndruPush(id);
      refresh();
    } catch (err) {
      setError(String(err));
    }
  }

  async function onResendPush(id: string) {
    setPushingId(id);
    setError('');
    setMessage('');
    try {
      await api.sendIndruPush(id);
      setMessage('Push notification sent.');
      refresh();
    } catch (err) {
      setError(String(err));
    } finally {
      setPushingId(null);
    }
  }

  return (
    <div>
      <h2>இன்று — Push notifications</h2>
      <p style={{ color: '#555', marginTop: 0 }}>
        Send on-demand notifications that open the <strong>இன்று</strong> tab in the app.
        Image is optional — use for highlights, birthdays, or daily promos.
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}

      <form className="card" onSubmit={onSubmit}>
        <h3 style={{ marginTop: 0 }}>New இன்று notification</h3>
        <label>Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="இன்று — தினசரி தகவல்கள்"
          required
        />
        <label>Body (optional)</label>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Short message shown under the title"
          rows={4}
        />
        <label>Image (optional)</label>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setFile(e.target.files?.[0] ?? null)}
        />
        <label className="toggle-row">
          <input
            type="checkbox"
            checked={sendPush}
            onChange={(e) => setSendPush(e.target.checked)}
          />
          <span>Send push notification to users</span>
        </label>
        <button type="submit" disabled={uploading}>
          {uploading ? 'Sending…' : sendPush ? 'Send notification' : 'Save only'}
        </button>
      </form>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>Sent notifications ({items.length})</h3>
        {items.length === 0 ? (
          <p>No இன்று push notifications yet.</p>
        ) : (
          <div className="story-grid">
            {items.map((row) => (
              <div key={row.id} className="story-card">
                {row.image_url ? (
                  <img src={row.image_url} alt={row.title} />
                ) : (
                  <div
                    style={{
                      height: 140,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      background: '#f5ebe0',
                      color: '#6b5344',
                      fontWeight: 600,
                    }}
                  >
                    Text only
                  </div>
                )}
                <div className="story-meta">
                  <strong>{row.title}</strong>
                  <span>{new Date(row.created_at).toLocaleString()}</span>
                  {row.push_sent && <span className="badge-push">Push sent</span>}
                  {row.body && (
                    <p style={{ whiteSpace: 'pre-wrap' }}>
                      {row.body.length > 120 ? `${row.body.slice(0, 120)}…` : row.body}
                    </p>
                  )}
                  <div className="post-actions">
                    <button
                      type="button"
                      className="secondary"
                      disabled={pushingId === row.id}
                      onClick={() => onResendPush(row.id)}
                    >
                      {pushingId === row.id ? 'Sending…' : 'Resend push'}
                    </button>
                    <button type="button" className="secondary" onClick={() => onDelete(row.id)}>
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
