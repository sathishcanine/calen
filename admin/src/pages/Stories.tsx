import { useEffect, useState, type FormEvent } from 'react';
import { api } from '../api';
import type { StatusStory } from '../api';

export default function Stories() {
  const [items, setItems] = useState<StatusStory[]>([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [uploading, setUploading] = useState(false);
  const [title, setTitle] = useState('');
  const [caption, setCaption] = useState('');
  const [file, setFile] = useState<File | null>(null);

  const refresh = () => {
    api
      .listStatusStories()
      .then(setItems)
      .catch((e) => setError(String(e)));
  };

  useEffect(() => {
    refresh();
  }, []);

  async function onUpload(e: FormEvent) {
    e.preventDefault();
    if (!file) {
      setError('Choose an image');
      return;
    }
    setUploading(true);
    setError('');
    setMessage('');
    try {
      await api.uploadStatusStory({ file, title, caption });
      setFile(null);
      setTitle('');
      setCaption('');
      setMessage('Story uploaded. Latest 10 appear in the mobile app.');
      refresh();
    } catch (err) {
      setError(String(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete this story?')) return;
    setError('');
    try {
      await api.deleteStatusStory(id);
      refresh();
    } catch (err) {
      setError(String(err));
    }
  }

  return (
    <div>
      <h2>Status stories</h2>
      <p style={{ color: '#555', marginTop: 0 }}>
        Upload photos here. Users can view and share only — no user uploads. The app shows the latest 10.
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}

      <form className="card" onSubmit={onUpload}>
        <h3 style={{ marginTop: 0 }}>Add story</h3>
        <label>Photo</label>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setFile(e.target.files?.[0] ?? null)}
        />
        <label>Title (optional)</label>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Short label" />
        <label>Caption (optional)</label>
        <textarea value={caption} onChange={(e) => setCaption(e.target.value)} placeholder="Share text" />
        <button type="submit" disabled={uploading}>
          {uploading ? 'Uploading…' : 'Upload story'}
        </button>
      </form>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>All stories ({items.length})</h3>
        {items.length === 0 ? (
          <p>No stories yet.</p>
        ) : (
          <div className="story-grid">
            {items.map((story) => (
              <div key={story.id} className="story-card">
                <img src={story.image_url} alt={story.title || story.id} />
                <div className="story-meta">
                  <strong>{story.title || 'Untitled'}</strong>
                  <span>{new Date(story.created_at).toLocaleString()}</span>
                  {story.caption && <p>{story.caption}</p>}
                  <button type="button" className="secondary" onClick={() => onDelete(story.id)}>
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
