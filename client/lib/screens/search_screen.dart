import 'package:flutter/material.dart';

import '../models/models.dart';
import 'tag_editor_screen.dart';
import '../extensions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    final results = provider.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索歌曲、专辑、歌手...',
            border: InputBorder.none,
          ),
          onChanged: (q) => provider.search(q),
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : _searchCtrl.text.isEmpty
              ? const Center(child: Text('输入关键词开始搜索'))
              : ListView(
                  children: [
                    if (results.containsKey('songs') && (results['songs'] as List).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('歌曲', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      ...(results['songs'] as List).map((s) {
                        final song = Song.fromJson(s);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(width: 40, height: 40, color: Colors.grey[800],
                              child: song.hasCover ? Image.network('${provider.api.baseUrl}/api/cover/${song.id}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 20)) : const Icon(Icons.music_note, size: 20)),
                          ),
                          title: Text(song.title),
                          subtitle: Text('${song.artist} · ${song.album}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => TagEditorScreen(song: song)));
                            },
                            itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('编辑标签'))],
                          ),
                          onTap: () => provider.playSong(song),
                        );
                      }),
                    ],
                    if (results.containsKey('albums') && (results['albums'] as List).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('专辑', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      ...(results['albums'] as List).map((a) {
                        final album = Album.fromJson(a);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(width: 48, height: 48, color: Colors.grey[800],
                              child: album.hasCover ? Image.network('${provider.api.baseUrl}/api/cover/${album.id}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.album)) : const Icon(Icons.album)),
                          ),
                          title: Text(album.name),
                          subtitle: Text('${album.artist} · ${album.songCount} 首'),
                        );
                      }),
                    ],
                    if (results.containsKey('artists') && (results['artists'] as List).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('歌手', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      ...(results['artists'] as List).map((a) {
                        final artist = Artist.fromJson(a);
                        return ListTile(
                          leading: CircleAvatar(child: Text(artist.name[0].toUpperCase())),
                          title: Text(artist.name),
                          subtitle: Text('${artist.albumCount} 张专辑 · ${artist.songCount} 首歌'),
                        );
                      }),
                    ],
                  ],
                ),
    );
  }
}
