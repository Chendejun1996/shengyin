import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MusicProvider extends ChangeNotifier {
  final ApiService api;
  final AudioPlayer _player = AudioPlayer();

  // Cached data
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Song> _songs = [];
  List<Song> _queue = [];
  Song? _currentSong;
  Map<String, dynamic> _searchResults = {};
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  bool _initialized = false;

  // Player state streams
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerErrorSub;

  // Exposed reactive state
  bool _isPlaying = false;
  double _position = 0;
  double _duration = 0;
  bool _playerLoading = false;

  // Getters
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Song> get songs => _songs;
  List<Song> get queue => _queue;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get playerLoading => _playerLoading;
  double get position => _position;
  double get duration => _duration;
  Map<String, dynamic> get searchResults => _searchResults;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  bool get initialized => _initialized;

  MusicProvider(this.api) {
    _playerErrorSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.idle && _currentSong != null) {
        // Playback finished or error — try next
        _playerLoading = false;
        notifyListeners();
      } else if (state == ProcessingState.buffering) {
        _playerLoading = true;
        notifyListeners();
      } else if (state == ProcessingState.ready) {
        _playerLoading = false;
        notifyListeners();
      }
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) notifyListeners();
    });

    _positionSub = _player.positionStream.listen((pos) {
      _position = pos?.inMilliseconds == null ? 0 : pos!.inMilliseconds / 1000.0;
    });

    _durationSub = _player.durationStream.listen((dur) {
      _duration = dur?.inMilliseconds == null ? 0 : dur!.inMilliseconds / 1000.0;
    });
  }

  @override
  void dispose() {
    _playerErrorSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void markInitialized() {
    _initialized = true;
  }

  // ─── Data Loading ──────

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
    if (q.isEmpty) return;
    setLoading(true);
    try {
      _searchResults = await api.search(q);
    } catch (_) {}
    setLoading(false);
  }

  // ─── Audio Playback ──────

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    _currentSong = song;
    _queue = queue ?? [song];
    notifyListeners();

    final url = api.getStreamUrl(song.id);
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      _playerLoading = false;
      notifyListeners();
    }
  }

  void togglePlay() {
    if (_currentSong == null) return;
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void stopPlayback() {
    _player.stop();
    _currentSong = null;
    _isPlaying = false;
    notifyListeners();
  }

  void seek(double pos) {
    _player.seek(Duration(milliseconds: (pos * 1000).toInt()));
  }

  void nextSong() {
    if (_queue.isEmpty) return;
    final idx = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (idx >= 0 && idx < _queue.length - 1) {
      playSong(_queue[idx + 1], queue: _queue);
    } else {
      playSong(_queue.first, queue: _queue);
    }
  }

  void prevSong() {
    if (_queue.isEmpty) return;
    final idx = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (idx > 0) {
      playSong(_queue[idx - 1], queue: _queue);
    } else {
      // Restart current song if near beginning
      if (_position > 3) {
        seek(0);
      } else {
        playSong(_queue.first, queue: _queue);
      }
    }
  }

  void setPosition(double pos) {
    _position = pos;
  }
}
