import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MusicProvider extends ChangeNotifier {
  final ApiService api;

  MusicProvider(this.api);

  // State
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Song> _songs = [];
  List<Song> _queue = [];
  Song? _currentSong;
  bool _isPlaying = false;
  double _position = 0;
  double _duration = 0;
  String _searchQuery = '';
  Map<String, dynamic> _searchResults = {};
  Map<String, dynamic> _stats = {};
  bool _loading = false;

  // Getters
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Song> get songs => _songs;
  List<Song> get queue => _queue;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  double get position => _position;
  double get duration => _duration;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get searchResults => _searchResults;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;

  // Actions
  void setLoading(bool v) { _loading = v; notifyListeners(); }

  Future<void> loadAlbums({String sort = 'name'}) async {
    setLoading(true);
    try {
      _albums = await api.getAlbums(sort: sort);
    } catch (_) {}
    setLoading(false);
  }

  Future<void> loadArtists() async {
    setLoading(true);
    try {
      _artists = await api.getArtists();
    } catch (_) {}
    setLoading(false);
  }

  Future<void> loadSongs({int? albumId, int? artistId}) async {
    setLoading(true);
    try {
      _songs = await api.getSongs(albumId: albumId, artistId: artistId);
    } catch (_) {}
    setLoading(false);
  }

  Future<void> loadStats() async {
    try {
      _stats = await api.stats();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> search(String q) async {
    _searchQuery = q;
    if (q.isEmpty) return;
    setLoading(true);
    try {
      _searchResults = await api.search(q);
    } catch (_) {}
    setLoading(false);
  }

  void playSong(Song song, {List<Song>? queue}) {
    _currentSong = song;
    _queue = queue ?? [song];
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void nextSong() {
    if (_queue.isEmpty) return;
    final idx = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (idx >= 0 && idx < _queue.length - 1) {
      _currentSong = _queue[idx + 1];
    } else {
      _currentSong = _queue.first;
    }
    notifyListeners();
  }

  void prevSong() {
    if (_queue.isEmpty) return;
    final idx = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (idx > 0) {
      _currentSong = _queue[idx - 1];
    }
    notifyListeners();
  }

  void setPosition(double pos) { _position = pos; notifyListeners(); }
}
