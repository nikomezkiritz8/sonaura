class SonauraTrack {
  final String id;
  final String title;
  final String artist;
  String coverUrl; // Quitamos el final para poder corregirla si es necesario
  final String quality;
  final int sampleRate;
  final int bitDepth;

  SonauraTrack({
    required this.id, 
    required this.title, 
    required this.artist, 
    required this.coverUrl,
    required this.quality,
    required this.sampleRate,
    required this.bitDepth,
  });

  factory SonauraTrack.fromJson(Map<String, dynamic> json, {String? defaultCover}) {
    String artistName = "Artista desconocido";
    if (json['artist'] != null && json['artist']['name'] != null) {
      artistName = json['artist']['name'];
    } else if (json['performer'] != null && json['performer']['name'] != null) {
      artistName = json['performer']['name'];
    }

    // Buscamos la carátula en el track, si no, usamos la del álbum, si no, el default
    String cover = defaultCover ?? "";
    if (json['album'] != null && json['album']['image'] != null) {
      cover = json['album']['image']['large'] ?? cover;
    }

    return SonauraTrack(
      id: json['id']?.toString() ?? "0",
      title: json['title'] ?? "Título desconocido",
      artist: artistName,
      coverUrl: cover,
      quality: (json['maximum_bit_depth'] ?? 16) > 16 ? "HI-RES" : "CD",
      sampleRate: json['maximum_sampling_rate']?.toInt() ?? 44,
      bitDepth: json['maximum_bit_depth']?.toInt() ?? 16,
    );
  }
}
