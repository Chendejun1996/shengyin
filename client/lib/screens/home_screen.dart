import 'package:flutter/material.dart';

import '../providers/music_provider.dart';
import '../models/models.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import '../extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.music.loadStats();
      context.music.loadAlbums();
      context.music.loadArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('笙音', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadStats();
          await provider.loadAlbums();
          await provider.loadArtists();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(icon: Icons.audiotrack, label: '歌曲', value: '${provider.stats['songs'] ?? 0}'),
                    _StatItem(icon: Icons.album, label: '专辑', value: '${provider.stats['albums'] ?? 0}'),
                    _StatItem(icon: Icons.person, label: '歌手', value: '${provider.stats['artists'] ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Refresh button (loads stats, not scan)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await provider.loadStats();
                await provider.loadAlbums();
                await provider.loadArtists();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已刷新')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            // Recent albums
            Text('专辑', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: provider.albums.isEmpty
                  ? const Center(child: Text('暂无专辑，下拉刷新加载'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.albums.length,
                      itemBuilder: (_, i) => _AlbumCard(album: provider.albums[i]),
                    ),
            ),
            const SizedBox(height: 24),

            // Artists
            Text('歌手', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (provider.artists.isEmpty)
              const Center(child: Text('暂无歌手'))
            else
              ...provider.artists.take(10).map((a) => ListTile(
                leading: CircleAvatar(child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : '?')),
                title: Text(a.name),
                subtitle: Text('${a.albumCount} 张专辑 · ${a.songCount} 首歌'),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(artistId: a.id, artistName: a.name),
                )),
              )),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(albumId: album.id, albumName: album.name),
      )),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 150, height: 150,
                color: Colors.grey[800],
                child: album.hasCover && album.id > 0
                    ? Image.network(
                        '${context.music.api.baseUrl}/api/cover/album/${album.id}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 48, color: Colors.grey),
                      )
                    : const Icon(Icons.album, size: 48, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
