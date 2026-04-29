"""
笙音 (ShengYin) - Main Server
FastAPI application entry point.
"""
import io
import json
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Query, Request, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel

from config import MUSIC_DIR, HOST, PORT
from database import init_db, get_db, Song, Album, Artist
from scanner import MusicScanner
from tag_editor import TagEditor
from streaming import stream_audio
from scraper import MusicScraper


# ─── 日志配置 ───
LOG_DIR = Path("/vol1/shengyin-logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
log_file = LOG_DIR / f"shengyin-server-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(str(log_file), encoding="utf-8"),
        logging.StreamHandler(sys.stdout),  # 同时输出到控制台
    ],
)
logger = logging.getLogger("shengyin")


# --- Data Models ---

class TagUpdate(BaseModel):
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    album_artist: Optional[str] = None
    genre: Optional[str] = None
    year: Optional[str] = None
    track: Optional[str] = None
    disc: Optional[str] = None


class BatchTagUpdate(BaseModel):
    paths: list[str]
    tags: TagUpdate


# --- App Setup ---

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("╔═══════════════════════════════════════╗")
    logger.info("║        笙音 ShengYin Server           ║")
    logger.info("║        音乐库: %s          ║" % MUSIC_DIR)
    logger.info("╚═══════════════════════════════════════╝")
    init_db()
    logger.info("数据库初始化完成")
    yield
    logger.info("笙音服务器关闭")

app = FastAPI(title="笙音 ShengYin", version="1.1.1", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


# ─── 请求日志中间件 ───
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info("→ %s %s", request.method, request.url.path)
    try:
        response = await call_next(request)
        if response.status_code >= 400:
            logger.warning("← %s %s → %d", request.method, request.url.path, response.status_code)
        else:
            logger.info("← %s %s → %d", request.method, request.url.path, response.status_code)
        return response
    except Exception as e:
        logger.error("✗ %s %s 异常: %s", request.method, request.url.path, str(e), exc_info=True)
        raise


# --- Helpers ---

def _song_to_dict(song: Song) -> dict:
    return {
        "id": song.id,
        "path": song.path,
        "title": song.title,
        "artist": song.artist,
        "album": song.album,
        "album_artist": song.album_artist,
        "genre": song.genre,
        "year": song.year,
        "track": song.track_number,
        "disc": song.disc_number,
        "duration": song.duration,
        "bitrate": song.bitrate,
        "sample_rate": song.sample_rate,
        "file_size": song.file_size,
        "format": song.file_format,
        "has_cover": song.has_cover,
    }


def _album_to_dict(album: Album) -> dict:
    return {
        "id": album.id,
        "name": album.name,
        "artist": album.artist,
        "album_artist": album.album_artist,
        "year": album.year,
        "genre": album.genre,
        "song_count": album.song_count,
        "duration": album.duration,
        "has_cover": album.has_cover,
    }


def _artist_to_dict(artist: Artist) -> dict:
    return {
        "id": artist.id,
        "name": artist.name,
        "album_count": artist.album_count,
        "song_count": artist.song_count,
    }


# --- System Routes ---

@app.get("/api/ping")
async def ping():
    return {"status": "ok", "version": "1.1.1", "name": "笙音 ShengYin"}


@app.get("/api/stats")
async def stats():
    db = get_db()
    try:
        return {
            "songs": db.query(Song).count(),
            "albums": db.query(Album).count(),
            "artists": db.query(Artist).count(),
            "music_dir": str(MUSIC_DIR),
        }
    finally:
        db.close()


# --- Scan Routes ---

@app.post("/api/scan")
async def scan():
    db = get_db()
    try:
        scanner = MusicScanner(db)
        logger.info("开始扫描音乐库: %s", MUSIC_DIR)
        result = scanner.scan()
        logger.info("扫描完成: %s 首歌, %s 张专辑, %s 位歌手",
                     result.get("songs", 0), result.get("albums", 0), result.get("artists", 0))
        return result
    except Exception as e:
        logger.error("扫描失败: %s", str(e), exc_info=True)
        raise
    finally:
        db.close()


# --- Album Routes ---

@app.get("/api/albums")
async def list_albums(sort: str = Query("name", description="Sort by: name, year, artist")):
    db = get_db()
    try:
        order_map = {
            "name": Album.name,
            "year": Album.year,
            "artist": Album.artist,
        }
        order = order_map.get(sort, Album.name)
        albums = db.query(Album).order_by(order).all()
        return {"albums": [_album_to_dict(a) for a in albums]}
    finally:
        db.close()


@app.get("/api/albums/{album_id}")
async def get_album(album_id: int):
    db = get_db()
    try:
        album = db.query(Album).filter(Album.id == album_id).first()
        if not album:
            raise HTTPException(status_code=404, detail="Album not found")
        songs = db.query(Song).filter(
            Song.album == album.name,
            Song.album_artist == album.album_artist,
        ).order_by(Song.disc_number, Song.track_number).all()
        return {
            "album": _album_to_dict(album),
            "songs": [_song_to_dict(s) for s in songs],
        }
    finally:
        db.close()


# --- Artist Routes ---

@app.get("/api/artists")
async def list_artists():
    db = get_db()
    try:
        artists = db.query(Artist).order_by(Artist.name).all()
        return {"artists": [_artist_to_dict(a) for a in artists]}
    finally:
        db.close()


@app.get("/api/artists/{artist_id}")
async def get_artist(artist_id: int):
    db = get_db()
    try:
        artist = db.query(Artist).filter(Artist.id == artist_id).first()
        if not artist:
            raise HTTPException(status_code=404, detail="Artist not found")
        albums = db.query(Album).filter(Album.artist == artist.name).order_by(Album.year).all()
        songs = db.query(Song).filter(Song.artist == artist.name).order_by(Song.album, Song.track_number).all()
        return {
            "artist": _artist_to_dict(artist),
            "albums": [_album_to_dict(a) for a in albums],
            "songs": [_song_to_dict(s) for s in songs],
        }
    finally:
        db.close()


# --- Song Routes ---

@app.get("/api/songs")
async def list_songs(album_id: Optional[int] = Query(None), artist_id: Optional[int] = Query(None)):
    db = get_db()
    try:
        q = db.query(Song)
        if album_id:
            album = db.query(Album).filter(Album.id == album_id).first()
            if album:
                q = q.filter(Song.album == album.name, Song.album_artist == album.album_artist)
        if artist_id:
            artist = db.query(Artist).filter(Artist.id == artist_id).first()
            if artist:
                q = q.filter(Song.artist == artist.name)
        songs = q.order_by(Song.album, Song.disc_number, Song.track_number).all()
        return {"songs": [_song_to_dict(s) for s in songs]}
    finally:
        db.close()


@app.get("/api/songs/{song_id}")
async def get_song(song_id: int):
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")
        return {"song": _song_to_dict(song)}
    finally:
        db.close()


# --- Streaming Routes ---

@app.get("/api/stream/{song_id}")
async def stream_song(song_id: int, request: Request):
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")
        return await stream_audio(song.path, request)
    finally:
        db.close()


@app.get("/api/cover/{song_id}")
async def get_cover(song_id: int):
    """Get cover art for a song — embedded or local file."""
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        # Try local cover files first
        p = Path(song.path)
        for cover_name in ("cover.jpg", "cover.png", "folder.jpg", "folder.png"):
            cover = p.parent / cover_name
            if cover.exists():
                ext = cover.suffix.lower()
                mime = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"
                return Response(content=cover.read_bytes(), media_type=mime)

        # Try embedded cover
        from mutagen import File as MutagenFile
        audio = MutagenFile(song.path)
        if audio is None:
            raise HTTPException(status_code=404, detail="No cover art found")

        if "APIC:" in audio:
            apic = audio["APIC:"]
            return Response(content=apic.data, media_type=apic.mime)
        if "covr" in audio and audio["covr"]:
            data = audio["covr"][0]
            return Response(content=data if isinstance(data, bytes) else data[1], media_type="image/jpeg")

        raise HTTPException(status_code=404, detail="No cover art found")
    finally:
        db.close()


@app.get("/api/cover/album/{album_id}")
async def get_album_cover(album_id: int):
    """Get cover art for an album — finds first song in album with cover."""
    db = get_db()
    try:
        album = db.query(Album).filter(Album.id == album_id).first()
        if not album:
            raise HTTPException(status_code=404, detail="Album not found")
        # Find first song in this album that has a cover
        song = db.query(Song).filter(
            Song.album == album.name,
            Song.album_artist == album.album_artist,
            Song.has_cover == True,
        ).first()
        if not song:
            # Fallback — any song in the album
            song = db.query(Song).filter(
                Song.album == album.name,
                Song.album_artist == album.album_artist,
            ).first()
        if not song:
            raise HTTPException(status_code=404, detail="No songs in album")
        # Reuse song cover logic
        p = Path(song.path)
        for cover_name in ("cover.jpg", "cover.png", "folder.jpg", "folder.png"):
            cover = p.parent / cover_name
            if cover.exists():
                ext = cover.suffix.lower()
                mime = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"
                return Response(content=cover.read_bytes(), media_type=mime)
        from mutagen import File as MutagenFile
        audio = MutagenFile(song.path)
        if audio:
            if "APIC:" in audio:
                apic = audio["APIC:"]
                return Response(content=apic.data, media_type=apic.mime)
            if "covr" in audio and audio["covr"]:
                data = audio["covr"][0]
                return Response(content=data if isinstance(data, bytes) else data[1], media_type="image/jpeg")
        raise HTTPException(status_code=404, detail="No cover art found")
    finally:
        db.close()


# --- Tag Editor Routes ---

@app.get("/api/tags/{song_id}")
async def read_tags(song_id: int):
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")
        editor = TagEditor()
        tags = editor.read(song.path)
        return {"tags": tags, "path": song.path}
    finally:
        db.close()


@app.put("/api/tags/{song_id}")
async def write_tags(song_id: int, update: TagUpdate):
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        editor = TagEditor()
        tags = {k: v for k, v in update.model_dump().items() if v is not None}
        result = editor.write(song.path, tags)
        return result
    finally:
        db.close()


@app.post("/api/tags/batch")
async def batch_write_tags(batch: BatchTagUpdate):
    editor = TagEditor()
    tags = {k: v for k, v in batch.tags.model_dump().items() if v is not None}
    results = editor.batch_write(batch.paths, tags)
    return {"results": results}


@app.post("/api/cover/{song_id}")
async def upload_cover(song_id: int, file: UploadFile = File(...)):
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        data = await file.read()
        mime = file.content_type or "image/jpeg"
        editor = TagEditor()
        result = editor.write_cover(song.path, data, mime)
        return result
    finally:
        db.close()


# --- Scraper Routes ---

@app.post("/api/scrape/{song_id}")
async def scrape_song(song_id: int):
    """Auto-scrape metadata for a single song."""
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        scraper = MusicScraper()
        result = scraper.scrape_song(song.path)
        return result
    finally:
        db.close()


@app.post("/api/scrape/album")
async def scrape_album(artist: str = Query(...), album: str = Query(...)):
    """Auto-scrape metadata for an entire album."""
    scraper = MusicScraper()
    result = scraper.scrape_album(artist, album)
    return result


@app.post("/api/scrape/apply/{song_id}")
async def apply_scraped(song_id: int):
    """Auto-scrape and apply metadata to a song."""
    db = get_db()
    try:
        song = db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        scraper = MusicScraper()
        scraped = scraper.scrape_song(song.path)
        if scraped.get("status") != "ok":
            return scraped
        result = scraper.apply_scraped_tags(song.path, scraped)
        return result
    finally:
        db.close()


# --- Search Route ---

@app.get("/api/search")
async def search(q: str = Query(..., min_length=1)):
    db = get_db()
    try:
        pattern = f"%{q}%"
        songs = db.query(Song).filter(
            Song.title.like(pattern) | Song.artist.like(pattern) | Song.album.like(pattern)
        ).limit(50).all()
        albums = db.query(Album).filter(
            Album.name.like(pattern) | Album.artist.like(pattern)
        ).limit(20).all()
        artists = db.query(Artist).filter(
            Artist.name.like(pattern)
        ).limit(20).all()

        return {
            "songs": [_song_to_dict(s) for s in songs],
            "albums": [_album_to_dict(a) for a in albums],
            "artists": [_artist_to_dict(a) for a in artists],
        }
    finally:
        db.close()


# --- Main Entry ---

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT)
