import { useRef } from 'react';
import { api } from '../api';

export type EditorBlock =
  | { id: string; type: 'text'; value: string }
  | { id: string; type: 'image'; filename: string; imageUrl: string; uploading?: boolean };

function newId(): string {
  return crypto.randomUUID();
}

export function emptyBlocks(): EditorBlock[] {
  return [{ id: newId(), type: 'text', value: '' }];
}

export function blocksForSubmit(blocks: EditorBlock[]) {
  return blocks
    .map((block) => {
      if (block.type === 'text') {
        return { type: 'text', value: block.value };
      }
      return { type: 'image', filename: block.filename };
    })
    .filter((block) => {
      if (block.type === 'text') return (block.value ?? '').trim().length > 0;
      return Boolean(block.filename);
    });
}

export function hasImageBlock(blocks: EditorBlock[]): boolean {
  return blocks.some((block) => block.type === 'image' && block.filename);
}

interface BlockEditorProps {
  blocks: EditorBlock[];
  onChange: (blocks: EditorBlock[]) => void;
  disabled?: boolean;
}

export default function BlockEditor({ blocks, onChange, disabled }: BlockEditorProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const pendingImageBlockId = useRef<string | null>(null);

  function updateBlock(id: string, patch: Partial<EditorBlock>) {
    onChange(
      blocks.map((block) => (block.id === id ? ({ ...block, ...patch } as EditorBlock) : block)),
    );
  }

  function removeBlock(id: string) {
    if (blocks.length <= 1) {
      onChange(emptyBlocks());
      return;
    }
    onChange(blocks.filter((block) => block.id !== id));
  }

  function moveBlock(id: string, direction: -1 | 1) {
    const index = blocks.findIndex((block) => block.id === id);
    const target = index + direction;
    if (index < 0 || target < 0 || target >= blocks.length) return;
    const next = [...blocks];
    const [item] = next.splice(index, 1);
    next.splice(target, 0, item);
    onChange(next);
  }

  function addTextBlock() {
    onChange([...blocks, { id: newId(), type: 'text', value: '' }]);
  }

  function addImageBlock() {
    const id = newId();
    pendingImageBlockId.current = id;
    onChange([...blocks, { id, type: 'image', filename: '', imageUrl: '', uploading: true }]);
    fileInputRef.current?.click();
  }

  async function onImageSelected(file: File | null, blockId: string) {
    if (!file) {
      onChange(blocks.filter((block) => block.id !== blockId || block.type !== 'image'));
      return;
    }
    updateBlock(blockId, { uploading: true });
    try {
      const uploaded = await api.uploadPostMedia(file);
      updateBlock(blockId, {
        filename: uploaded.filename,
        imageUrl: uploaded.image_url,
        uploading: false,
      });
    } catch (err) {
      removeBlock(blockId);
      throw err;
    }
  }

  return (
    <div className="block-editor">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        hidden
        onChange={(e) => {
          const blockId = pendingImageBlockId.current;
          const file = e.target.files?.[0] ?? null;
          e.target.value = '';
          pendingImageBlockId.current = null;
          if (!blockId) return;
          void onImageSelected(file, blockId).catch(() => {
            /* parent shows error */
          });
        }}
      />

      {blocks.map((block, index) => (
        <div key={block.id} className="block-editor-item">
          <div className="block-editor-toolbar">
            <span className="block-editor-label">
              {block.type === 'text' ? `Text ${index + 1}` : `Image ${index + 1}`}
            </span>
            <div className="block-editor-actions">
              <button
                type="button"
                className="secondary small"
                disabled={disabled || index === 0}
                onClick={() => moveBlock(block.id, -1)}
              >
                ↑
              </button>
              <button
                type="button"
                className="secondary small"
                disabled={disabled || index === blocks.length - 1}
                onClick={() => moveBlock(block.id, 1)}
              >
                ↓
              </button>
              <button
                type="button"
                className="secondary small"
                disabled={disabled}
                onClick={() => removeBlock(block.id)}
              >
                Remove
              </button>
            </div>
          </div>

          {block.type === 'text' ? (
            <textarea
              value={block.value}
              disabled={disabled}
              placeholder="Write a paragraph…"
              rows={5}
              onChange={(e) => updateBlock(block.id, { value: e.target.value })}
            />
          ) : (
            <div className="block-editor-image">
              {block.uploading ? (
                <p>Uploading image…</p>
              ) : block.imageUrl ? (
                <img src={block.imageUrl} alt="" />
              ) : (
                <p>No image selected</p>
              )}
            </div>
          )}
        </div>
      ))}

      <div className="block-editor-add-row">
        <button type="button" className="secondary" disabled={disabled} onClick={addTextBlock}>
          + Add text
        </button>
        <button type="button" className="secondary" disabled={disabled} onClick={addImageBlock}>
          + Add image
        </button>
      </div>
    </div>
  );
}
