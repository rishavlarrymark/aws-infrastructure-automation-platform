from collections.abc import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from app.config import settings

# Explicitly require PostgreSQL at runtime; no silent SQLite fallback.
if not settings.database_url.startswith(("postgresql://", "postgresql+psycopg://", "postgresql+psycopg2://")):
    raise RuntimeError("DATABASE_URL must use PostgreSQL (postgresql+psycopg://...)")

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    connect_args={"connect_timeout": 5},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
