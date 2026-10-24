
from collections.abc import Generator
from urllib.parse import quote

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings


database_url = (
    f"postgresql+psycopg://{quote(settings.db_user, safe='')}:"
    f"{quote(settings.db_password, safe='')}@"
    f"{settings.db_host}:{settings.db_port}/"
    f"{quote(settings.db_name, safe='')}"
)

connect_args = {"connect_timeout": 5}

if settings.db_sslmode != "disable":
    connect_args["sslmode"] = settings.db_sslmode

engine = create_engine(
    database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    connect_args=connect_args,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
