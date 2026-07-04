import { useEffect, useState, type FormEvent } from 'react';
import { api } from '../api';
import type { BookCategory, LibraryBook } from '../api';

export default function Books() {
  const [categories, setCategories] = useState<BookCategory[]>([]);
  const [books, setBooks] = useState<LibraryBook[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [uploading, setUploading] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [title, setTitle] = useState('');
  const [author, setAuthor] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<File | null>(null);

  const refreshCategories = () => {
    api
      .listBookCategories()
      .then((cats) => {
        setCategories(cats);
        if (!selectedCategoryId && cats.length > 0) {
          setSelectedCategoryId(cats[0].id);
        }
      })
      .catch((e) => setError(String(e)));
  };

  const refreshBooks = (categoryId: string) => {
    if (!categoryId) {
      setBooks([]);
      return;
    }
    api
      .listBooks(categoryId)
      .then(setBooks)
      .catch((e) => setError(String(e)));
  };

  useEffect(() => {
    refreshCategories();
  }, []);

  useEffect(() => {
    refreshBooks(selectedCategoryId);
  }, [selectedCategoryId]);

  async function onCreateCategory(e: FormEvent) {
    e.preventDefault();
    const name = newCategoryName.trim();
    if (!name) {
      setError('Enter a category name');
      return;
    }
    setError('');
    setMessage('');
    try {
      const cat = await api.createBookCategory(name);
      setNewCategoryName('');
      setMessage(`Category "${cat.name}" created.`);
      refreshCategories();
      setSelectedCategoryId(cat.id);
    } catch (err) {
      setError(String(err));
    }
  }

  async function onUpload(e: FormEvent) {
    e.preventDefault();
    if (!selectedCategoryId) {
      setError('Select a category');
      return;
    }
    if (!file) {
      setError('Choose a PDF file');
      return;
    }
    setUploading(true);
    setError('');
    setMessage('');
    try {
      await api.uploadBook({
        file,
        categoryId: selectedCategoryId,
        title,
        author,
        preview,
      });
      setFile(null);
      setPreview(null);
      setTitle('');
      setAuthor('');
      setMessage('PDF uploaded successfully.');
      refreshCategories();
      refreshBooks(selectedCategoryId);
    } catch (err) {
      setError(String(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDeleteCategory(id: string, name: string) {
    if (!confirm(`Delete category "${name}" and all its books?`)) return;
    setError('');
    try {
      await api.deleteBookCategory(id);
      setMessage(`Category "${name}" deleted.`);
      if (selectedCategoryId === id) {
        setSelectedCategoryId('');
        setBooks([]);
      }
      refreshCategories();
    } catch (err) {
      setError(String(err));
    }
  }

  async function onDeleteBook(id: string, bookTitle: string) {
    if (!confirm(`Delete "${bookTitle}"?`)) return;
    setError('');
    try {
      await api.deleteBook(id);
      refreshCategories();
      refreshBooks(selectedCategoryId);
    } catch (err) {
      setError(String(err));
    }
  }

  return (
    <div>
      <h2>Books library</h2>
      <p style={{ color: '#555', marginTop: 0 }}>
        Manage PDF categories and upload books. A lightweight preview image is auto-generated from the first PDF
        page (or upload your own cover). The mobile app shows previews only — PDF downloads when the user opens a
        book.
      </p>
      {error && <p className="error">{error}</p>}
      {message && <p className="success">{message}</p>}

      <div className="card">
        <h3 style={{ marginTop: 0 }}>Categories</h3>
        <form onSubmit={onCreateCategory} style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
          <input
            value={newCategoryName}
            onChange={(e) => setNewCategoryName(e.target.value)}
            placeholder="New category name"
            style={{ flex: '1 1 200px' }}
          />
          <button type="submit">Add category</button>
        </form>
        {categories.length === 0 ? (
          <p>No categories yet.</p>
        ) : (
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {categories.map((cat) => (
              <li
                key={cat.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  padding: '8px 0',
                  borderBottom: '1px solid #eee',
                }}
              >
                <button
                  type="button"
                  className={selectedCategoryId === cat.id ? '' : 'secondary'}
                  onClick={() => setSelectedCategoryId(cat.id)}
                >
                  {cat.name}
                </button>
                <span style={{ color: '#666', fontSize: 14 }}>
                  {cat.book_count} book{cat.book_count === 1 ? '' : 's'}
                </span>
                <button
                  type="button"
                  className="secondary"
                  style={{ marginLeft: 'auto' }}
                  onClick={() => onDeleteCategory(cat.id, cat.name)}
                >
                  Delete
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <form className="card" onSubmit={onUpload}>
        <h3 style={{ marginTop: 0 }}>Upload PDF</h3>
        <label>Category</label>
        <select
          value={selectedCategoryId}
          onChange={(e) => setSelectedCategoryId(e.target.value)}
          disabled={categories.length === 0}
        >
          {categories.length === 0 ? (
            <option value="">Create a category first</option>
          ) : (
            categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))
          )}
        </select>
        <label>PDF file</label>
        <input
          type="file"
          accept="application/pdf,.pdf"
          onChange={(e) => setFile(e.target.files?.[0] ?? null)}
        />
        <label>Cover preview (optional — auto-generated from PDF if omitted)</label>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setPreview(e.target.files?.[0] ?? null)}
        />
        <label>Title (optional — defaults to filename)</label>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Book title" />
        <label>Author (optional)</label>
        <input value={author} onChange={(e) => setAuthor(e.target.value)} placeholder="Author name" />
        <button type="submit" disabled={uploading || categories.length === 0}>
          {uploading ? 'Uploading…' : 'Upload PDF'}
        </button>
      </form>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>
          Books in {categories.find((c) => c.id === selectedCategoryId)?.name ?? 'category'} ({books.length})
        </h3>
        {books.length === 0 ? (
          <p>No books in this category yet.</p>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', borderBottom: '2px solid #ddd' }}>
                <th style={{ padding: 8 }}>Preview</th>
                <th style={{ padding: 8 }}>Title</th>
                <th style={{ padding: 8 }}>Author</th>
                <th style={{ padding: 8 }}>Size</th>
                <th style={{ padding: 8 }}></th>
              </tr>
            </thead>
            <tbody>
              {books.map((book) => (
                <tr key={book.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: 8 }}>
                    {book.preview_url ? (
                      <img
                        src={book.preview_url}
                        alt=""
                        style={{ width: 48, height: 64, objectFit: 'cover', borderRadius: 4 }}
                      />
                    ) : (
                      '—'
                    )}
                  </td>
                  <td style={{ padding: 8 }}>
                    <a href={book.pdf_url} target="_blank" rel="noreferrer">
                      {book.title}
                    </a>
                  </td>
                  <td style={{ padding: 8 }}>{book.author || '—'}</td>
                  <td style={{ padding: 8 }}>{formatBytes(book.file_size)}</td>
                  <td style={{ padding: 8 }}>
                    <button type="button" className="secondary" onClick={() => onDeleteBook(book.id, book.title)}>
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
