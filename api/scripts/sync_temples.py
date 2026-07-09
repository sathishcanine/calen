from app.database import SessionLocal
from app.data.temples_service import sync_temples


def main() -> None:
    db = SessionLocal()
    try:
        count = sync_temples(db)
        print(f"Curated temples seeded successfully: {count}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
