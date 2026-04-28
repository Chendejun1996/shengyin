class Song {
  final int id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int year;
  final int track;
  final int disc;
  final double duration;
  final int bitrate;
  final int sampleRate;
  final int fileSize;
  final String format;
  final bool hasCover;

  Song({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    this.genre = '',
    this.year = 0,
    this.track = 0,
    this.disc = 0,
    this.duration = 0,
    this.bitrate = 0,
    this.sampleRate = 0,
    this.fileSize = 0,
    this.format = '',
    this.hasCover = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? 0,
      path: json['path'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      album: json['album'] ?? 'Unknown',
      albumArtist: json['album_artist'] ?? '',
      genre: json['genre'] ?? '',
      year: json['year'] ?? 0,
      track: json['track'] ?? 0,
      disc: json['disc'] ?? 0,
      duration: (json['duration'] ?? 0).toDouble(),
      bitrate: json['bitrate'] ?? 0,
      sampleRate: json['sample_rate'] ?? 0,
      fileSize: json['file_size'] ?? 0,
      format: json['format'] ?? '',
      hasCover: json['has_cover'] ?? false,
    );
  }
}

class Album {
  final int id;
  final String name;
  final String artist;
  final String albumArtist;
  final int year;
  final String genre;
  final int songCount;
  final double duration;
  final bool hasCover;

  Album({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArtist = '',
    this.year = 0,
    this.genre = '',
    this.songCount = 0,
    this.duration = 0,
    this.hasCover = false,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      albumArtist: json['album_artist'] ?? '',
      year: json['year'] ?? 0,
      genre: json['genre'] ?? '',
      songCount: json['song_count'] ?? 0,
      duration: (json['duration'] ?? 0).toDouble(),
      hasCover: json['has_cover'] ?? false,
    );
  }
}

class Artist {
  final int id;
  final String name;
  final int albumCount;
  final int songCount;

  Artist({
    required this.id,
    required this.name,
    this.albumCount = 0,
    this.songCount = 0,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      albumCount: json['album_count'] ?? 0,
      songCount: json['song_count'] ?? 0,
    );
  }
}
