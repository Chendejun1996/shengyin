"""
笙音 (ShengYin) - Auto Scraper
Automatic metadata and cover art scraping from MusicBrainz.
"""
import io
import json
import urllib.request
from pathlib import Path
from typing import Optional

import musicbrainzngs

from config import MUSICBRAINZ_USERAGENT
from tag_editor import TagEditor

musicbrainzngs.set_useragent(MUSICBRAINZ_USERAGENT, "0.1.0", "https://github.com/Chendejun1996/shengyin")


class MusicScraper:
    """Auto-scrape music metadata using MusicBrainz."""

    def __init__(self):
        self.editor = TagEditor()

    def scrape_song(self, path: str) -> dict:
        """Try to identify and scrape metadata for a single song."""
        tags = self.editor.read(path)
        if "error" in tags:
            return tags

        results = musicbrainzngs.search_recordings(
            artist=tags.get("artist", ""),
            recording=tags.get("title", ""),
            limit=5,
        )
        recordings = results.get("recording-list", [])
        if not recordings:
            return {"status": "error", "message": "No match found on MusicBrainz"}

        best = recordings[0]
        release_id = None
        if best.get("release-list"):
            release_id = best["release-list"][0]["id"]

        result = {
            "status": "ok",
            "title": best.get("title", tags["title"]),
            "artist": best.get("artist-credit", [{}])[0].get("artist", {}).get("name", tags["artist"]),
            "mbid": best["id"],
        }

        if release_id:
            result["release_id"] = release_id
            release = musicbrainzngs.get_release_by_id(release_id, includes=["recordings", "artists", "cover-art-archive"])
            r = release.get("release", {})
            if r.get("title"):
                result["album"] = r["title"]
            if r.get("date"):
                result["year"] = r["date"][:4]
            if r.get("artist-credit"):
                result["album_artist"] = r["artist-credit"][0].get("artist", {}).get("name", "")

            # Check if cover art is available
            if r.get("cover-art-archive", {}).get("artwork", "false") == "true":
                result["has_cover"] = True

        return result

    def scrape_album(self, artist: str, album: str) -> dict:
        """Scrape album metadata by artist and album name."""
        results = musicbrainzngs.search_releases(
            artist=artist,
            release=album,
            limit=5,
        )
        releases = results.get("release-list", [])
        if not releases:
            return {"status": "error", "message": "No album match found on MusicBrainz"}

        best = releases[0]
        rid = best["id"]

        release = musicbrainzngs.get_release_by_id(
            rid,
            includes=["recordings", "artists", "cover-art-archive", "tags"]
        )
        r = release.get("release", {})

        tracks = []
        for medium in r.get("medium-list", []):
            for track in medium.get("track-list", []):
                rec = track.get("recording", {})
                tracks.append({
                    "title": rec.get("title", ""),
                    "track": track.get("position", 0),
                    "mbid": rec.get("id", ""),
                })

        data = {
            "status": "ok",
            "album": r.get("title", album),
            "artist": artist,
            "album_artist": r.get("artist-credit", [{}])[0].get("artist", {}).get("name", ""),
            "year": (r.get("date", "") or "")[:4],
            "genre": " / ".join(t.get("name", "") for t in (r.get("tag-list") or [])[:3]),
            "track_count": len(tracks),
            "tracks": tracks,
            "release_id": rid,
            "has_cover": r.get("cover-art-archive", {}).get("artwork", "false") == "true",
        }

        return data

    def download_cover(self, release_id: str) -> Optional[bytes]:
        """Download cover art for a MusicBrainz release."""
        url = f"https://coverartarchive.org/release/{release_id}/front"
        try:
            req = urllib.request.Request(url, headers={"User-Agent": MUSICBRAINZ_USERAGENT})
            with urllib.request.urlopen(req, timeout=15) as resp:
                return resp.read()
        except Exception:
            return None

    def apply_scraped_tags(self, path: str, scraped: dict) -> dict:
        """Apply scraped metadata to a song file."""
        tags = {}
        if scraped.get("title"):
            tags["title"] = scraped["title"]
        if scraped.get("artist"):
            tags["artist"] = scraped["artist"]
        if scraped.get("album"):
            tags["album"] = scraped["album"]
        if scraped.get("album_artist"):
            tags["album_artist"] = scraped["album_artist"]
        if scraped.get("year"):
            tags["year"] = scraped["year"]

        result = self.editor.write(path, tags)

        # Also download cover if available
        if scraped.get("has_cover") and scraped.get("release_id"):
            cover = self.download_cover(scraped["release_id"])
            if cover:
                self.editor.write_cover(path, cover)

        return result
