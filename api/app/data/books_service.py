"""PDF library — categories, books, previews, and file storage."""

from __future__ import annotations

import io
import re
import uuid
from pathlib import Path

from PIL import Image
from sqlalchemy.orm import Session

from app.models import BookCategory, LibraryBook

DATA_DIR = Path(__file__).resolve().parent / "books"
PDFS_DIR = DATA_DIR / "pdfs"
PREVIEWS_DIR = DATA_DIR / "previews"

ALLOWED_EXTENSIONS = {".pdf"}
PREVIEW_UPLOAD_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_PDF_BYTES = 50 * 1024 * 1024  # 50 MB
MAX_PREVIEW_UPLOAD_BYTES = 5 * 1024 * 1024  # 5 MB
PREVIEW_MAX_WIDTH = 420

DEFAULT_CATEGORIES: list[tuple[str, str, int]] = [
    ("aanmeegam", "Aanmeegam", 1),
    ("kavidhaigal", "Kavidhaigal", 2),
    ("naavalgal", "Naavalgal", 3),
    ("siru-kadhaigal", "Siru-kadhaigal", 4),
    ("varalaru", "Varalaru", 5),
]


def _ensure_dirs() -> None:
    PDFS_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEWS_DIR.mkdir(parents=True, exist_ok=True)


def _slugify(name: str) -> str:
    slug = name.strip().lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = slug.strip("-")
    return slug or str(uuid.uuid4())[:8]


def _preview_stored_name(book_id: str) -> str:
    return f"{book_id}.webp"


def _resize_to_webp(img: Image.Image, out_path: Path) -> None:
    img = img.convert("RGB")
    if img.width > PREVIEW_MAX_WIDTH:
        ratio = PREVIEW_MAX_WIDTH / img.width
        img = img.resize((PREVIEW_MAX_WIDTH, int(img.height * ratio)), Image.Resampling.LANCZOS)
    img.save(out_path, "WEBP", quality=82, method=6)


def save_uploaded_preview(book_id: str, content: bytes, original_filename: str) -> str:
    if not content:
        raise ValueError("Empty preview image")
    if len(content) > MAX_PREVIEW_UPLOAD_BYTES:
        raise ValueError("Preview image exceeds 5 MB limit")

    ext = Path(original_filename).suffix.lower()
    if ext not in PREVIEW_UPLOAD_EXTENSIONS:
        raise ValueError("Preview must be JPG, PNG, or WebP")

    _ensure_dirs()
    stored_name = _preview_stored_name(book_id)
    out_path = PREVIEWS_DIR / stored_name
    with Image.open(io.BytesIO(content)) as img:
        _resize_to_webp(img, out_path)
    return stored_name


def generate_pdf_preview(pdf_bytes: bytes, book_id: str) -> str | None:
    """Render first PDF page as a compact WebP thumbnail."""
    try:
        import fitz  # PyMuPDF
    except ImportError:
        return None

    _ensure_dirs()
    stored_name = _preview_stored_name(book_id)
    out_path = PREVIEWS_DIR / stored_name

    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        if doc.page_count == 0:
            doc.close()
            return None
        page = doc.load_page(0)
        scale = 2.0 if page.rect.width < 400 else 1.5
        pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
        img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
        _resize_to_webp(img, out_path)
        doc.close()
        return stored_name
    except Exception:
        return None


def delete_preview_file(preview_filename: str | None) -> None:
    if not preview_filename:
        return
    (PREVIEWS_DIR / preview_filename).unlink(missing_ok=True)


def seed_default_categories(db: Session) -> None:
    for cat_id, name, order in DEFAULT_CATEGORIES:
        existing = db.get(BookCategory, cat_id)
        if existing is None:
            db.add(BookCategory(id=cat_id, name=name, sort_order=order))
    db.commit()


def list_categories(db: Session) -> list[BookCategory]:
    return db.query(BookCategory).order_by(BookCategory.sort_order, BookCategory.name).all()


def create_category(db: Session, *, name: str) -> BookCategory:
    base_id = _slugify(name)
    cat_id = base_id
    suffix = 1
    while db.get(BookCategory, cat_id) is not None:
        cat_id = f"{base_id}-{suffix}"
        suffix += 1

    max_order = db.query(BookCategory.sort_order).order_by(BookCategory.sort_order.desc()).first()
    order = (max_order[0] if max_order else 0) + 1

    row = BookCategory(id=cat_id, name=name.strip(), sort_order=order)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def delete_category(db: Session, category_id: str) -> bool:
    row = db.get(BookCategory, category_id)
    if not row:
        return False
    for book in list(row.books):
        delete_book(db, book.id)
    db.delete(row)
    db.commit()
    return True


def list_books(db: Session, category_id: str | None = None) -> list[LibraryBook]:
    q = db.query(LibraryBook).order_by(LibraryBook.sort_order, LibraryBook.title)
    if category_id:
        q = q.filter(LibraryBook.category_id == category_id)
    return q.all()


def add_book(
    db: Session,
    *,
    category_id: str,
    title: str,
    content: bytes,
    original_filename: str,
    author: str = "",
    preview_content: bytes | None = None,
    preview_original_filename: str | None = None,
) -> LibraryBook:
    if not content:
        raise ValueError("Empty file")
    if len(content) > MAX_PDF_BYTES:
        raise ValueError("PDF exceeds 50 MB limit")

    ext = Path(original_filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError("Only PDF files are allowed")

    category = db.get(BookCategory, category_id)
    if not category:
        raise ValueError("Category not found")

    _ensure_dirs()
    book_id = str(uuid.uuid4())
    stored_name = f"{book_id}{ext}"
    (PDFS_DIR / stored_name).write_bytes(content)

    preview_filename: str | None = None
    if preview_content:
        preview_filename = save_uploaded_preview(
            book_id,
            preview_content,
            preview_original_filename or "cover.jpg",
        )
    else:
        preview_filename = generate_pdf_preview(content, book_id)

    max_order = (
        db.query(LibraryBook.sort_order)
        .filter(LibraryBook.category_id == category_id)
        .order_by(LibraryBook.sort_order.desc())
        .first()
    )
    order = (max_order[0] if max_order else 0) + 1

    row = LibraryBook(
        id=book_id,
        category_id=category_id,
        title=title.strip() or Path(original_filename).stem,
        filename=stored_name,
        preview_filename=preview_filename,
        author=author.strip(),
        file_size=len(content),
        sort_order=order,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def delete_book(db: Session, book_id: str) -> bool:
    row = db.get(LibraryBook, book_id)
    if not row:
        return False
    pdf_path = PDFS_DIR / row.filename
    pdf_path.unlink(missing_ok=True)
    delete_preview_file(row.preview_filename)
    db.delete(row)
    db.commit()
    return True


def pdf_path(filename: str) -> Path:
    return PDFS_DIR / filename


def book_count_for_category(db: Session, category_id: str) -> int:
    return db.query(LibraryBook).filter(LibraryBook.category_id == category_id).count()
