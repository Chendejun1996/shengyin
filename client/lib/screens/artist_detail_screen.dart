import 'package:flutter/material.dart';
import '../main.dart';
import 'tag_editor_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final int artistId;
  final String artistName;
  const ArtistDetailScreen({super.key, required this.artistId, required this.artistName});
  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.music.loadSongs(artistId: widget.artistId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName)),
      body: provider.songs.isEmpty
          ? const Center(child: Text('暂无歌曲'))
          : ListView.builder(
              itemCount: provider.songs.length,
              itemBuilder: (_, i) {
                final song = provider.songs[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 40, height: 40, color: Colors.grey[800],
                      child: song.hasCover
                          ? Image.network('${provider.api.baseUrl}/api/cover/${song.id}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note))
                          : const Icon(Icons.music_note, color: Colors.grey),
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.album),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TagEditorScreen(song: song),
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
    );
  }
}
