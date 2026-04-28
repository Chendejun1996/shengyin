<div align="center">
  <h1>🎶 笙音 · ShengYin</h1>
  <p><em>一个集音乐播放与标签编辑于一体的现代音乐服务器</em></p>
  <p>
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT">
    <img src="https://img.shields.io/badge/python-3.11+-green.svg" alt="Python">
    <img src="https://img.shields.io/badge/flutter-3.x-blue.svg" alt="Flutter">
    <img src="https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20windows%20%7C%20linux%20%7C%20macos-brightgreen" alt="Platform">
    <img src="https://github.com/Chendejun1996/shengyin/actions/workflows/build.yml/badge.svg" alt="Build">
  </p>
</div>

---

## 🌟 为什么做笙音？

[Navidrome](https://github.com/navidrome/navidrome) 有着漂亮的播放界面，但缺少标签编辑功能；[music-tag-web](https://github.com/xhongc/music-tag-web) 能编辑标签，却没有播放器。

**笙音 = Navidrome 的播放体验 + music-tag-web 的标签编辑，融为一体。**

- 🎵 **播放音乐** — 流媒体播放、专辑浏览、歌手页面
- 🏷️ **编辑标签** — 修改标题、歌手、专辑、封面、歌词
- 📡 **自动刮削** — 从 MusicBrainz 自动识别并补全元数据
- 🖥️ **全平台** — Android / iOS / Windows / Linux / macOS

## 🏗️ 架构

```
┌──────────────────────────────────────────┐
│             笙音 Server (FastAPI)          │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐   │
│  │ Streaming│ │ Tags读写 │ │ 自动刮削  │   │
│  └─────────┘ └──────────┘ └──────────┘   │
│          统一 REST API (端口 4534)          │
└──────────────────┬───────────────────────┘
                   │ HTTP
                   ▼
┌──────────────────────────────────────────┐
│         笙音 Client (Flutter)              │
│   Android · iOS · Windows · Linux · macOS  │
│  一个代码库，六个平台                          │
└──────────────────────────────────────────┘
```

## 🚀 快速开始

### 服务端部署

#### 使用 Docker

```bash
docker run -d \
  --name shengyin \
  -p 4534:4534 \
  -v /path/to/music:/music:ro \
  -v /path/to/data:/data \
  ghcr.io/Chendejun1996/shengyin:latest
```

#### 手动运行

```bash
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 设置音乐目录
export SHENGYIN_MUSIC_DIR=/path/to/music
export SHENGYIN_DB_PATH=/path/to/data/shengyin.db

# 启动
python main.py
```

首次启动后访问 **http://localhost:4534/api/ping** 确认运行正常，然后调用 **POST /api/scan** 扫描音乐库。

### 客户端编译

需要安装 [Flutter SDK](https://flutter.dev)：

```bash
cd client
flutter pub get

# Android
flutter build apk

# iOS (需 macOS)
flutter build ios

# Windows
flutter build windows

# Linux
flutter build linux

# macOS
flutter build macos
```

## 📡 API 概览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/ping` | 健康检查 |
| POST | `/api/scan` | 扫描音乐库 |
| GET | `/api/stats` | 统计信息 |
| GET | `/api/albums` | 专辑列表 |
| GET | `/api/albums/{id}` | 专辑详情 |
| GET | `/api/artists` | 歌手列表 |
| GET | `/api/artists/{id}` | 歌手详情 |
| GET | `/api/songs` | 歌曲列表 |
| GET | `/api/songs/{id}` | 歌曲详情 |
| GET | `/api/stream/{id}` | 音频流播放 |
| GET | `/api/cover/{id}` | 封面图片 |
| PUT | `/api/tags/{id}` | 编辑标签 |
| POST | `/api/scrape/{id}` | 自动刮削 |
| GET | `/api/search?q=` | 搜索 |

## 📜 开源许可

[MIT License](LICENSE) — 自由使用、修改、商用。

## 🙏 致谢

- [Navidrome](https://github.com/navidrome/navidrome) — 播放器 UI 灵感
- [music-tag-web](https://github.com/xhongc/music-tag-web) — 标签编辑器 UI 灵感
- [mutagen](https://github.com/quodlibet/mutagen) — 音频标签读写
- [musicbrainzngs](https://github.com/alastair/musicbrainzngs) — MusicBrainz API
- [FastAPI](https://fastapi.tiangolo.com/) — Python 后端框架
- [Flutter](https://flutter.dev) — 跨平台客户端框架
