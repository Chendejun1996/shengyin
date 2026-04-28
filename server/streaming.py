"""
笙音 (ShengYin) - Audio Streaming
Stream audio files with transcoding support.
"""
import asyncio
import mimetypes
from pathlib import Path

from fastapi import HTTPException, Request
from fastapi.responses import StreamingResponse, FileResponse


async def stream_audio(path: str, request: Request, transcode: bool = False):
    """Stream an audio file, supporting range requests for seeking."""
    p = Path(path)
    if not p.exists():
        raise HTTPException(status_code=404, detail="File not found")

    file_size = p.stat().st_size
    range_header = request.headers.get("range")

    if range_header:
        return await _stream_range(p, file_size, range_header)

    mime, _ = mimetypes.guess_type(str(p))
    if not mime:
        ext = p.suffix.lower()
        mime_map = {
            ".mp3": "audio/mpeg",
            ".flac": "audio/flac",
            ".ogg": "audio/ogg",
            ".opus": "audio/ogg",
            ".m4a": "audio/mp4",
            ".wav": "audio/wav",
            ".wv": "audio/wavpack",
            ".ape": "audio/x-ape",
            ".dsf": "audio/dsf",
        }
        mime = mime_map.get(ext, "application/octet-stream")

    return FileResponse(
        path=p,
        media_type=mime,
        filename=p.name,
        headers={
            "Accept-Ranges": "bytes",
            "Cache-Control": "no-cache",
        }
    )


async def _stream_range(path: Path, file_size: int, range_header: str):
    """Handle HTTP range requests for seeking support."""
    range_val = range_header.strip().removeprefix("bytes=")
    parts = range_val.split("-")
    start = int(parts[0]) if parts[0] else 0
    end = int(parts[1]) if len(parts) > 1 and parts[1] else file_size - 1

    if start >= file_size:
        raise HTTPException(status_code=416, detail="Range not satisfiable")

    content_length = end - start + 1

    async def file_iterator():
        with open(path, "rb") as f:
            f.seek(start)
            remaining = content_length
            while remaining > 0:
                chunk_size = min(65536, remaining)
                data = f.read(chunk_size)
                if not data:
                    break
                remaining -= len(data)
                yield data

    mime, _ = mimetypes.guess_type(str(path))
    return StreamingResponse(
        file_iterator(),
        media_type=mime or "audio/mpeg",
        status_code=206,
        headers={
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Content-Length": str(content_length),
            "Accept-Ranges": "bytes",
        }
    )
