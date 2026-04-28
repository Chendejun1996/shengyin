"""
笙音 (ShengYin) - Database Models
"""
import datetime
from sqlalchemy import create_engine, Column, Integer, String, Text, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker

from config import DB_PATH

DB_PATH.parent.mkdir(parents=True, exist_ok=True)

engine = create_engine(f"sqlite:///{DB_PATH}", echo=False)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


class Song(Base):
    __tablename__ = "songs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    path = Column(String(1024), unique=True, nullable=False, index=True)
    title = Column(String(512), default="")
    artist = Column(String(512), default="")
    album = Column(String(512), default="")
    album_artist = Column(String(512), default="")
    genre = Column(String(256), default="")
    year = Column(Integer, default=0)
    track_number = Column(Integer, default=0)
    disc_number = Column(Integer, default=0)
    duration = Column(Float, default=0.0)
    bitrate = Column(Integer, default=0)
    sample_rate = Column(Integer, default=0)
    file_size = Column(Integer, default=0)
    file_format = Column(String(16), default="")
    has_cover = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)


class Album(Base):
    __tablename__ = "albums"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(512), nullable=False, index=True)
    artist = Column(String(512), default="")
    album_artist = Column(String(512), default="")
    year = Column(Integer, default=0)
    genre = Column(String(256), default="")
    song_count = Column(Integer, default=0)
    duration = Column(Float, default=0.0)
    has_cover = Column(Boolean, default=False)
    cover_path = Column(String(1024), default="")


class Artist(Base):
    __tablename__ = "artists"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(512), unique=True, nullable=False, index=True)
    album_count = Column(Integer, default=0)
    song_count = Column(Integer, default=0)


def init_db():
    Base.metadata.create_all(engine)


def get_db():
    db = SessionLocal()
    try:
        return db
    finally:
        db.close()
