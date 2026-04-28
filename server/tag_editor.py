"""
笙音 (ShengYin) - Tag Editor
Read and write music file metadata using mutagen.
"""
from pathlib import Path
from mutagen import File as MutagenFile
from mutagen.flac import FLAC, Picture
from mutagen.id3 import ID3, APIC, TIT2, TPE1, TALB, TCON, TDRC, TRCK, TPE2, TPOS
from mutagen.mp4 import MP4, MP4Cover
from mutagen.oggvorbis import OggVorbis

from config import AUDIO_EXTENSIONS


class TagEditor:
    """Read and edit music file tags."""

    SUPPORTED = {'.mp3', '.flac', '.ogg', '.m4a', '.opus', '.wav', '.ape', '.wv', '.dsf'}

    def read(self, path: str) -> dict:
        """Read tags from a music file."""
        p = Path(path)
        if p.suffix.lower() not in self.SUPPORTED:
            return {"error": f"Unsupported format: {p.suffix}"}

        audio = MutagenFile(str(p))
        if audio is None:
            return {"error": "Cannot read file"}

        tags = audio.tags or {}

        if isinstance(audio, MP4):
            return self._read_mp4(tags)
        elif isinstance(audio, ID3):
            return self._read_id3(tags)
        else:
            return self._read_vorbis(tags)

    def _read_id3(self, tags) -> dict:
        def g(frame):
            try:
                return str(tags[frame])
            except:
                return ""
        return {
            "title": g("TIT2") or g("TIT1"),
            "artist": g("TPE1"),
            "album": g("TALB"),
            "album_artist": g("TPE2"),
            "genre": g("TCON"),
            "year": g("TDRC")[:4] if g("TDRC") else "",
            "track": g("TRCK"),
            "disc": g("TPOS"),
            "has_cover": "APIC:" in tags,
        }

    def _read_mp4(self, tags) -> dict:
        return {
            "title": "\n".join(tags.get("\xa9nam", [])),
            "artist": "\n".join(tags.get("\xa9ART", [])),
            "album": "\n".join(tags.get("\xa9alb", [])),
            "album_artist": "\n".join(tags.get("aART", [])),
            "genre": "\n".join(tags.get("\xa9gen", [])),
            "year": str(tags.get("\xa9day", [""])[0])[:4] if tags.get("\xa9day") else "",
            "track": str(tags.get("trkn", [(0, 0)])[0][0]),
            "disc": str(tags.get("disk", [(0, 0)])[0][0]),
            "has_cover": "covr" in tags,
        }

    def _read_vorbis(self, tags) -> dict:
        return {
            "title": tags.get("title", [""])[0],
            "artist": tags.get("artist", [""])[0],
            "album": tags.get("album", [""])[0],
            "album_artist": tags.get("albumartist", [""])[0] or tags.get("album artist", [""])[0],
            "genre": tags.get("genre", [""])[0],
            "year": (tags.get("date", [""])[0])[:4],
            "track": tags.get("tracknumber", [""])[0],
            "disc": tags.get("discnumber", [""])[0],
            "has_cover": any(k.startswith("metadata_block_picture") for k in tags.keys()),
        }

    def write(self, path: str, tags: dict) -> dict:
        """Write tags to a music file."""
        p = Path(path)
        if not p.exists():
            return {"error": "File not found"}

        audio = MutagenFile(str(p))
        if audio is None:
            return {"error": "Cannot read file"}

        try:
            self._apply_tags(audio, tags)
            audio.save()
            return {"status": "ok", "path": path}
        except Exception as e:
            return {"error": str(e)}

    def _apply_tags(self, audio, tags: dict):
        """Apply tag changes to audio object."""
        if isinstance(audio, MP4):
            if "title" in tags:
                audio["\xa9nam"] = [tags["title"]]
            if "artist" in tags:
                audio["\xa9ART"] = [tags["artist"]]
            if "album" in tags:
                audio["\xa9alb"] = [tags["album"]]
            if "album_artist" in tags:
                audio["aART"] = [tags["album_artist"]]
            if "genre" in tags:
                audio["\xa9gen"] = [tags["genre"]]
            if "year" in tags:
                audio["\xa9day"] = [tags["year"]]
            if "track" in tags:
                try:
                    n = int(tags["track"].split("/")[0])
                    audio["trkn"] = [(n, 0)]
                except:
                    pass
        elif hasattr(audio, "add_tags") or hasattr(audio, "save"):
            if isinstance(audio, FLAC):
                self._write_vorbis(audio, tags)
            elif isinstance(audio, OggVorbis):
                self._write_vorbis(audio, tags)
            else:
                self._write_vorbis(audio, tags)

    def _write_vorbis(self, audio, tags: dict):
        """Write Vorbis-style tags."""
        mapping = {
            "title": "title", "artist": "artist", "album": "album",
            "album_artist": "albumartist", "genre": "genre",
            "year": "date", "track": "tracknumber", "disc": "discnumber",
        }
        for key, vorbis_key in mapping.items():
            if key in tags and tags[key]:
                audio[vorbis_key] = [tags[key]]
            elif key in tags and not tags[key]:
                audio.pop(vorbis_key, None)

    def write_cover(self, path: str, cover_data: bytes, mime: str = "image/jpeg") -> dict:
        """Embed cover art into a music file."""
        p = Path(path)
        audio = MutagenFile(str(p))
        if audio is None:
            return {"error": "Cannot read file"}

        try:
            if isinstance(audio, MP4):
                ext = "jpg" if "jpeg" in mime else "png"
                audio["covr"] = [MP4Cover(cover_data, MP4Cover.FORMAT_JPEG if ext == "jpg" else MP4Cover.FORMAT_PNG)]
            elif isinstance(audio, FLAC):
                pic = Picture()
                pic.data = cover_data
                pic.type = 3  # Cover (front)
                pic.mime = mime
                pic.desc = "Cover (front)"
                audio.add_picture(pic)
            elif isinstance(audio, ID3):
                audio.add(APIC(encoding=3, mime=mime, type=3, desc="Cover (front)", data=cover_data))
            else:
                return {"error": f"Cover writing not supported for {p.suffix}"}
            audio.save()
            return {"status": "ok"}
        except Exception as e:
            return {"error": str(e)}

    def batch_write(self, paths: list[str], tags: dict) -> list[dict]:
        """Apply the same tag changes to multiple files."""
        results = []
        for path in paths:
            results.append(self.write(path, tags))
        return results
