class SonauraAlbum {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final int tracksCount;

  SonauraAlbum({
    required this.id, 
    required this.title, 
    required this.artist, 
    required this.coverUrl,
    this.tracksCount = 0,
  });

  factory SonauraAlbum.fromJson(Map<String, dynamic> json) {
    return SonauraAlbum(
      id: json['id'].toString(),
      title: json['title'] ?? "Álbum desconocido",
      artist: (json['artist'] != null) ? (json['artist']['name'] ?? "Artista") : "Artista",
      coverUrl: (json['image'] != null) ? (json['image']['large'] ?? "") : "",
      tracksCount: json['tracks_count'] ?? 0,
    );
  }
}
