import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  String _baseUrl;

  ApiService(String baseUrl) : _baseUrl = baseUrl;

  set baseUrl(String url) => _baseUrl = url;
  String get baseUrl => _baseUrl;

  // --- System ---

  Future<Map<String, dynamic>> ping() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/ping'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> stats() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/stats'));
    return jsonDecode(res.body);
  }

  // --- Scan ---

  Future<Map<String, dynamic>> scan() async {
    final res = await http.post(Uri.parse('$_baseUrl/api/scan'));
    return jsonDecode(res.body);
  }

  // --- Albums ---

  Future<List<Album>> getAlbums({String sort = 'name'}) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/albums?sort=$sort'));
    final data = jsonDecode(res.body);
    return (data['albums'] as List).map((e) => Album.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getAlbum(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/albums/$id'));
    return jsonDecode(res.body);
  }

  // --- Artists ---

  Future<List<Artist>> getArtists() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/artists'));
    final data = jsonDecode(res.body);
    return (data['artists'] as List).map((e) => Artist.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getArtist(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/artists/$id'));
    return jsonDecode(res.body);
  }

  // --- Songs ---

  Future<List<Song>> getSongs({int? albumId, int? artistId}) async {
    String url = '$_baseUrl/api/songs';
    if (albumId != null) url += '?album_id=$albumId';
    if (artistId != null) url += '${albumId != null ? "&" : "?"}artist_id=$artistId';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    return (data['songs'] as List).map((e) => Song.fromJson(e)).toList();
  }

  Future<Song> getSong(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/songs/$id'));
    final data = jsonDecode(res.body);
    return Song.fromJson(data['song']);
  }

  String getStreamUrl(int songId) => '$_baseUrl/api/stream/$songId';
  String getCoverUrl(int songId) => '$_baseUrl/api/cover/$songId';

  // --- Search ---

  Future<Map<String, dynamic>> search(String query) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/search?q=${Uri.encodeComponent(query)}'));
    return jsonDecode(res.body);
  }

  // --- Tags ---

  Future<Map<String, dynamic>> readTags(int songId) async {
    final res = await http.get(Uri.parse('$_baseUrl/api/tags/$songId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> writeTags(int songId, Map<String, String> tags) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/tags/$songId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tags),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> batchWriteTags(List<String> paths, Map<String, String> tags) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/tags/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'paths': paths, 'tags': tags}),
    );
    return jsonDecode(res.body);
  }

  // --- Scraper ---

  Future<Map<String, dynamic>> scrapeSong(int songId) async {
    final res = await http.post(Uri.parse('$_baseUrl/api/scrape/$songId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> scrapeAlbum(String artist, String album) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/scrape/album?artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> applyScraped(int songId) async {
    final res = await http.post(Uri.parse('$_baseUrl/api/scrape/apply/$songId'));
    return jsonDecode(res.body);
  }
}
