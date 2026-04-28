import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class TagEditorScreen extends StatefulWidget {
  final Song song;
  const TagEditorScreen({super.key, required this.song});
  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _albumCtrl;
  late TextEditingController _albumArtistCtrl;
  late TextEditingController _genreCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _trackCtrl;
  late TextEditingController _discCtrl;
  bool _scraping = false;
  Map<String, dynamic>? _scrapedData;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.song.title);
    _artistCtrl = TextEditingController(text: widget.song.artist);
    _albumCtrl = TextEditingController(text: widget.song.album);
    _albumArtistCtrl = TextEditingController(text: widget.song.albumArtist);
    _genreCtrl = TextEditingController(text: widget.song.genre);
    _yearCtrl = TextEditingController(text: widget.song.year > 0 ? '${widget.song.year}' : '');
    _trackCtrl = TextEditingController(text: widget.song.track > 0 ? '${widget.song.track}' : '');
    _discCtrl = TextEditingController(text: widget.song.disc > 0 ? '${widget.song.disc}' : '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _albumArtistCtrl.dispose();
    _genreCtrl.dispose();
    _yearCtrl.dispose();
    _trackCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tags = <String, String>{};
    if (_titleCtrl.text.trim().isNotEmpty) tags['title'] = _titleCtrl.text.trim();
    if (_artistCtrl.text.trim().isNotEmpty) tags['artist'] = _artistCtrl.text.trim();
    if (_albumCtrl.text.trim().isNotEmpty) tags['album'] = _albumCtrl.text.trim();
    if (_albumArtistCtrl.text.trim().isNotEmpty) tags['album_artist'] = _albumArtistCtrl.text.trim();
    if (_genreCtrl.text.trim().isNotEmpty) tags['genre'] = _genreCtrl.text.trim();
    if (_yearCtrl.text.trim().isNotEmpty) tags['year'] = _yearCtrl.text.trim();
    if (_trackCtrl.text.trim().isNotEmpty) tags['track'] = _trackCtrl.text.trim();
    if (_discCtrl.text.trim().isNotEmpty) tags['disc'] = _discCtrl.text.trim();

    try {
      await context.music.api.writeTags(widget.song.id, tags);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标签已保存'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _scrape() async {
    setState(() => _scraping = true);
    try {
      final result = await context.music.api.scrapeSong(widget.song.id);
      setState(() {
        _scrapedData = result;
        if (result['status'] == 'ok') {
          if (result['title'] != null) _titleCtrl.text = result['title'];
          if (result['artist'] != null) _artistCtrl.text = result['artist'];
          if (result['album'] != null) _albumCtrl.text = result['album'];
          if (result['album_artist'] != null) _albumArtistCtrl.text = result['album_artist'];
          if (result['year'] != null) _yearCtrl.text = result['year'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('刮削失败: $e')));
      }
    }
    setState(() => _scraping = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑标签'),
        actions: [
          IconButton(
            icon: _scraping
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_download),
            tooltip: '自动刮削',
            onPressed: _scraping ? null : _scrape,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_scrapedData != null && _scrapedData!['status'] == 'ok')
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('已识别: ${_scrapedData!['title'] ?? ''}', style: const TextStyle(color: Colors.green))),
                    ],
                  ),
                ),
              ),
            if (_scrapedData != null && _scrapedData!['status'] != 'ok')
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text('未匹配到元数据', style: const TextStyle(color: Colors.orange))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _TagField(label: '标题', controller: _titleCtrl),
            _TagField(label: '歌手', controller: _artistCtrl),
            _TagField(label: '专辑', controller: _albumCtrl),
            _TagField(label: '专辑歌手', controller: _albumArtistCtrl),
            _TagField(label: '流派', controller: _genreCtrl),
            _TagField(label: '年份', controller: _yearCtrl),
            Row(
              children: [
                Expanded(child: _TagField(label: '音轨号', controller: _trackCtrl)),
                const SizedBox(width: 16),
                Expanded(child: _TagField(label: '碟号', controller: _discCtrl)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TagField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
