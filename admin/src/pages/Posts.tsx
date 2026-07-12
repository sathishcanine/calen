import { useEffect, useState, type FormEvent } from 'react';
import { api } from '../api';
import type { Post } from '../api';
import BlockEditor, {
  blocksForSubmit,
  emptyBlocks,
  hasImageBlock,
  type EditorBlock,
} from '../components/BlockEditor';

function postPreview(post: Post): string {
  if (post.blocks?.length) {
    const text = post.blocks
      .filter((block) => block.type === 'text')
      .map((block) => block.value ?? '')
      .join(' ')
      .trim();
    if (text) return text.length > 120 ? `${text.slice(0, 119)}…` : text;
  }
  const plain = (post.content || '').trim();
  if (!plain || plain.startsWith('[')) return '';
  return plain.length > 120 ? `${plain.slice(0, 119)}…` : plain;
}

export default function Posts() {
  const [items, setItems] = useState<Post[]>([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [uploading, setUploading] = useState(false);
  const [title, setTitle] = useState('');
  const [blocks, setBlocks] = useState<EditorBlock[]>(emptyBlocks());
  const [cover, setCover] = useState<File | null>(null);
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
    const payload = blocksForSubmit(blocks);
    if (payload.length === 0) {
      setError('Add at least one text or image block');
      return;
    }
    if (!hasImageBlock(blocks) && !cover) {
      setError('Add at least one image block (or choose a cover thumbnail)');
      return;
    }
    if (blocks.some((block) => block.type === 'image' && block.uploading)) {
      setError('Wait for image uploads to finish');
      return;
    }
    setUploading(true);
    setError('');
    setMessage('');
    try {
      const post = await api.createPost({ title, blocks: payload, cover, sendPush });
      setTitle('');
      setBlocks(emptyBlocks());
      setCover(null);
      setSendPush(false);
      setMessage(
        sendPush
          ? 'Published and push notification sent.'
          : 'Published (no push notification).',
      );
      refresh();
      if (sendPush && !post.push_sent) {
        setMessage('Saved, but push failed — check FIREBASE_CREDENTIALS_PATH on the API.');
      }
    } catch (err) {
      setError(String(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete this entry?')) return;
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
      <h2>கூடிய தகவல்</h2>
      <p style={{ color: '#555', marginTop: 0 }}>
        Build blog-style content in Description — add text paragraphs and images in any order.
        The first image is used as the list thumbnail (or choose an optional cover below).
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}

      <form className="card" onSubmit={onSubmit}>
        <h3 style={{ marginTop: 0 }}>Add entry</h3>
        <label>Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Title"
          required
        />
        <label>Description (blog content)</label>
        <BlockEditor blocks={blocks} onChange={setBlocks} disabled={uploading} />
        <label>Optional cover thumbnail</label>
        <p className="field-hint">
          Used only for the app list card when you want a different image than the first block image.
        </p>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setCover(e.target.files?.[0] ?? null)}
        />
        <label className="toggle-row">
          <input
            type="checkbox"
            checked={sendPush}
            onChange={(e) => setSendPush(e.target.checked)}
          />
          <span>Send notification</span>
        </label>
        <button type="submit" disabled={uploading}>
          {uploading ? 'Publishing…' : 'Publish'}
        </button>
      </form>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>All entries ({items.length})</h3>
        {items.length === 0 ? (
          <p>No entries yet.</p>
        ) : (
          <div className="story-grid">
            {items.map((post) => (
              <div key={post.id} className="story-card">
                <img src={post.image_url} alt={post.title} />
                <div className="story-meta">
                  <strong>{post.title}</strong>
                  <span>{new Date(post.created_at).toLocaleString()}</span>
                  {post.push_sent && <span className="badge-push">Push sent</span>}
                  {postPreview(post) && (
                    <p style={{ whiteSpace: 'pre-wrap' }}>{postPreview(post)}</p>
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
