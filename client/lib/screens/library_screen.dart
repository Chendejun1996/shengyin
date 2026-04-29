import 'package:flutter/material.dart';

import '../models/models.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'tag_editor_screen.dart';
import '../extensions.dart';
import '../providers/music_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.music.loadAlbums();
      context.music.loadArtists();
      context.music.loadSongs();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    return Scaffold(
      appBar: AppBar(
        title: const Text('曲库'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.album), text: '专辑'),
            Tab(icon: Icon(Icons.person), text: '歌手'),
            Tab(icon: Icon(Icons.audiotrack), text: '歌曲'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Albums tab
          provider.albums.isEmpty
              ? const Center(child: Text('暂无专辑'))
              : ListView.builder(
                  itemCount: provider.albums.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 56, height: 56,
                        color: Colors.grey[800],
                        child: provider.albums[i].hasCover
                            ? Image.network('${provider.api.baseUrl}/api/cover/album/${provider.albums[i].id}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.album))
                            : const Icon(Icons.album, color: Colors.grey),
                      ),
                    ),
                    title: Text(provider.albums[i].name),
                    subtitle: Text('${provider.albums[i].artist} · ${provider.albums[i].songCount} 首'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(albumId: provider.albums[i].id, albumName: provider.albums[i].name),
                    )),
                  ),
                ),

          // Artists tab
          provider.artists.isEmpty
              ? const Center(child: Text('暂无歌手'))
              : ListView.builder(
                  itemCount: provider.artists.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(child: Text(provider.artists[i].name[0].toUpperCase())),
                    title: Text(provider.artists[i].name),
                    subtitle: Text('${provider.artists[i].albumCount} 张专辑 · ${provider.artists[i].songCount} 首歌'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(artistId: provider.artists[i].id, artistName: provider.artists[i].name),
                    )),
                  ),
                ),

          // Songs tab
          provider.songs.isEmpty
              ? const Center(child: Text('暂无歌曲'))
              : ListView.builder(
                  itemCount: provider.songs.length,
                  itemBuilder: (_, i) => _SongTile(song: provider.songs[i], provider: provider),
                ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final MusicProvider provider;
  const _SongTile({required this.song, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 40, height: 40,
          color: Colors.grey[800],
          child: song.hasCover
              ? Image.network('${provider.api.baseUrl}/api/cover/${song.id}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 20))
              : const Icon(Icons.music_note, size: 20, color: Colors.grey),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${song.artist} · ${_formatDuration(song.duration)}', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'play') provider.playSong(song, queue: provider.songs);
          if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => TagEditorScreen(song: song)));
          if (v == 'scrape') _scrape(context);
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'play', child: ListTile(leading: Icon(Icons.play_arrow), title: Text('播放'))),
          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('编辑标签'))),
          const PopupMenuItem(value: 'scrape', child: ListTile(leading: Icon(Icons.cloud_download), title: Text('自动刮削'))),
        ],
      ),
      onTap: () => provider.playSong(song, queue: provider.songs),
    );
  }

  Future<void> _scrape(BuildContext context) async {
    try {
      final result = await provider.api.applyScraped(song.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['status'] == 'ok' ? '刮削完成: ${result['title'] ?? song.title}' : '刮削失败')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('刮削错误: $e')));
      }
    }
  }

  String _formatDuration(double sec) {
    if (sec <= 0) return '0:00';
    final m = (sec ~/ 60);
    final s = (sec % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
