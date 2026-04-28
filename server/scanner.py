"""
笙音 (ShengYin) - Music Scanner
Scans music directory and builds/updates the library database.
"""
import hashlib
from pathlib import Path
from mutagen import File as MutagenFile
from sqlalchemy.orm import Session

from config import MUSIC_DIR, AUDIO_EXTENSIONS, COVER_FILES
from database import Song, Album, Artist


class MusicScanner:
    def __init__(self, db: Session):
        self.db = db

    def scan(self) -> dict:
        """Scan music directory, add new songs, update existing ones."""
        if not MUSIC_DIR.exists():
            return {"status": "error", "message": f"Music directory not found: {MUSIC_DIR}"}

        stats = {"total": 0, "added": 0, "updated": 0, "errors": 0}
        existing_paths = {s.path for s in self.db.query(Song.path).all()}

        for f in sorted(MUSIC_DIR.rglob("*")):
            if f.suffix.lower() not in AUDIO_EXTENSIONS:
                continue
            stats["total"] += 1
            try:
                if str(f) in existing_paths:
                    continue  # Skip unchanged files for now
                info = self._extract_info(f)
                song = Song(**info)
                self.db.add(song)
                stats["added"] += 1
            except Exception as e:
                stats["errors"] += 1

        self.db.commit()
        self._update_albums()
        self._update_artists()
        self.db.commit()

        return {
            "status": "ok",
            "total": stats["total"],
            "added": stats["added"],
            "errors": stats["errors"],
        }

    def _extract_info(self, path: Path) -> dict:
        """Extract metadata from a music file."""
        audio = MutagenFile(str(path))
        if audio is None:
            raise ValueError(f"Cannot read: {path}")

        stat = path.stat()
        duration = audio.info.length if hasattr(audio.info, "length") else 0
        bitrate = audio.info.bitrate if hasattr(audio.info, "bitrate") else 0
        sample_rate = audio.info.sample_rate if hasattr(audio.info, "sample_rate") else 0

        tags = audio.tags or {}
        cover_path = self._find_cover(path)

        def g(tag, default=""):
            val = tags.get(tag)
            if val:
                return str(val[0]) if isinstance(val, list) else str(val)
            return default

        title = g("title") or path.stem
        artist = g("artist") or "Unknown Artist"
        album = g("album") or "Unknown Album"

        year_str = g("date", "0")
        try:
            year = int(year_str[:4])
        except (ValueError, IndexError):
            year = 0

        return {
            "path": str(path),
            "title": title,
            "artist": artist,
            "album": album,
            "album_artist": g("albumartist") or g("album artist") or artist,
            "genre": g("genre"),
            "year": year,
            "track_number": int(g("tracknumber", "0").split("/")[0]) if g("tracknumber", "0") else 0,
            "disc_number": int(g("discnumber", "0").split("/")[0]) if g("discnumber", "0") else 0,
            "duration": duration,
            "bitrate": bitrate,
            "sample_rate": sample_rate,
            "file_size": stat.st_size,
            "file_format": path.suffix.lower().lstrip("."),
            "has_cover": self._has_cover_art(audio) or cover_path is not None,
        }

    def _find_cover(self, song_path: Path) -> str | None:
        """Look for cover image in the same directory."""
        for cover_name in COVER_FILES:
            cover = song_path.parent / cover_name
            if cover.exists():
                return str(cover)
        return None

    def _has_cover_art(self, audio) -> bool:
        """Check if the audio file has embedded cover art."""
        try:
            if "APIC:" in audio:
                return True
            if "covr" in audio and audio["covr"]:
                return True
            for key in audio.keys():
                if key.startswith("APIC"):
                    return True
        except:
            pass
        return False

    def _update_albums(self):
        """Rebuild album table from songs."""
        self.db.query(Album).delete()
        from sqlalchemy import func
        rows = self.db.query(
            Song.album, Song.album_artist,
            func.count(Song.id), func.sum(Song.duration),
            func.max(Song.year), func.max(Song.has_cover)
        ).group_by(Song.album, Song.album_artist).all()

        for name, artist, count, dur, year, has_cover in rows:
            album = Album(
                name=name or "Unknown Album",
                artist=artist or "Unknown Artist",
                album_artist=artist or "Unknown Artist",
                year=year or 0,
                song_count=count or 0,
                duration=dur or 0.0,
                has_cover=bool(has_cover),
            )
            self.db.add(album)

    def _update_artists(self):
        """Rebuild artist table from songs."""
        self.db.query(Artist).delete()
        from sqlalchemy import func
        rows = self.db.query(
            Song.artist,
            func.count(func.distinct(Song.album)),
            func.count(Song.id),
        ).group_by(Song.artist).all()

        for name, album_count, song_count in rows:
            artist = Artist(
                name=name or "Unknown Artist",
                album_count=album_count or 0,
                song_count=song_count or 0,
            )
            self.db.add(artist)
