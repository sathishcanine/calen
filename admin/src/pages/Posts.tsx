import { useEffect, useState, type FormEvent } from 'react';
import { api } from '../api';
import type { Post } from '../api';

export default function Posts() {
  const [items, setItems] = useState<Post[]>([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [uploading, setUploading] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [sendPush, setSendPush] = useState(false);
  const [pushingId, setPushingId] = useState<string | null>(null);

  const refresh = () => {
    api
      .listPosts()
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
    if (!file) {
      setError('Choose an image');
      return;
    }
    setUploading(true);
    setError('');
    setMessage('');
    try {
      const post = await api.createPost({ file, title, content, sendPush });
      setFile(null);
      setTitle('');
      setContent('');
      setSendPush(false);
      setMessage(
        sendPush
          ? 'Post published and push notification sent.'
          : 'Post published (no push notification).',
      );
      refresh();
      if (sendPush && !post.push_sent) {
        setMessage('Post saved, but push failed — check FIREBASE_CREDENTIALS_PATH on the API.');
      }
    } catch (err) {
      setError(String(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete this post?')) return;
    setError('');
    try {
      await api.deletePost(id);
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
      await api.pushPost(id);
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
      <h2>Posts</h2>
      <p style={{ color: '#555', marginTop: 0 }}>
        Publish image + text posts. Toggle push to notify app users — tapping opens the post detail screen.
        Line breaks in content are preserved in the app.
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}

      <form className="card" onSubmit={onSubmit}>
        <h3 style={{ marginTop: 0 }}>New post</h3>
        <label>Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Post title"
          required
        />
        <label>Content</label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Post body — blank lines create paragraph spacing in the app"
          rows={8}
        />
        <label>Image</label>
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
          {uploading ? 'Publishing…' : 'Publish post'}
        </button>
      </form>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>All posts ({items.length})</h3>
        {items.length === 0 ? (
          <p>No posts yet.</p>
        ) : (
          <div className="story-grid">
            {items.map((post) => (
              <div key={post.id} className="story-card">
                <img src={post.image_url} alt={post.title} />
                <div className="story-meta">
                  <strong>{post.title}</strong>
                  <span>{new Date(post.created_at).toLocaleString()}</span>
                  {post.push_sent && <span className="badge-push">Push sent</span>}
                  {post.content && (
                    <p style={{ whiteSpace: 'pre-wrap' }}>
                      {post.content.length > 120 ? `${post.content.slice(0, 120)}…` : post.content}
                    </p>
                  )}
                  <div className="post-actions">
                    <button
                      type="button"
                      className="secondary"
                      disabled={pushingId === post.id}
                      onClick={() => onResendPush(post.id)}
                    >
                      {pushingId === post.id ? 'Sending…' : 'Send push'}
                    </button>
                    <button type="button" className="secondary" onClick={() => onDelete(post.id)}>
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
