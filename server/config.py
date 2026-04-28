"""
笙音 (ShengYin) - Music Server Configuration
"""
import os
from pathlib import Path

# 音乐目录 — 默认指向 Navidrome 已有的音乐库
MUSIC_DIR = Path(os.environ.get("SHENGYIN_MUSIC_DIR", "/vol1/@appshare/navidrome/music"))

# 数据库
DB_PATH = Path(os.environ.get("SHENGYIN_DB_PATH", "/vol1/1000/Docker/shengyin/data/shengyin.db"))

# 服务器
HOST = os.environ.get("SHENGYIN_HOST", "0.0.0.0")
PORT = int(os.environ.get("SHENGYIN_PORT", "4534"))

# 支持的音频格式
AUDIO_EXTENSIONS = {
    '.mp3', '.flac', '.ogg', '.m4a', '.wav', '.wv',
    '.ape', '.aiff', '.dsf', '.opus', '.mpc', '.tta',
}

# 封面文件名称
COVER_FILES = {'cover.jpg', 'cover.png', 'folder.jpg', 'folder.png', 'album.jpg', 'album.png'}

# 刮削
MUSICBRAINZ_USERAGENT = "ShengYin/0.1.0 (Music Player)"
