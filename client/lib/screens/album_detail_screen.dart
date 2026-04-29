import 'package:flutter/material.dart';

import '../providers/music_provider.dart';
import '../models/models.dart';
import '../extensions.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;
  final String albumName;
  const AlbumDetailScreen({super.key, required this.albumId, required this.albumName});
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (_loaded) return;
    _loaded = true;
    try {
      context.music.loadSongs(albumId: widget.albumId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.albumName)),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Album header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 160, height: 160,
                          color: Colors.grey[800],
                          child: widget.albumId > 0
                              ? Image.network('${provider.api.baseUrl}/api/cover/album/${widget.albumId}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 64))
                              : const Icon(Icons.album, size: 64),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.albumName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('${provider.songs.length} 首歌曲'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Song list
                Expanded(
                  child: provider.songs.isEmpty
                      ? const Center(child: Text('暂无歌曲'))
                      : ListView.builder(
                    itemCount: provider.songs.length,
                    itemBuilder: (_, i) {
                      final song = provider.songs[i];
                      return ListTile(
                        leading: Text('${song.track}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        title: Text(song.title),
                        subtitle: Text(_formatDuration(song.duration)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: Text('编辑: ${song.title}')),
                                  body: const Center(child: Text('标签编辑页面')),
                                ),
                              ));
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('编辑标签')),
                          ],
                        ),
                        onTap: () => provider.playSong(song, queue: provider.songs),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDuration(double sec) {
    if (sec <= 0) return '0:00';
    final m = (sec ~/ 60);
    final s = (sec % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
