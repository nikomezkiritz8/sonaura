class SonauraTrack {
  final String id;
  final String title;
  final String artist;
  String coverUrl;
  final String quality;
  final int sampleRate;
  final int bitDepth;
  final bool isLocal; // Nuevo

  SonauraTrack({
    required this.id, 
    required this.title, 
    required this.artist, 
    required this.coverUrl,
    required this.quality,
    required this.sampleRate,
    required this.bitDepth,
    this.isLocal = false, // Por defecto es streaming
  });

  factory SonauraTrack.fromJson(Map<String, dynamic> json, {String? defaultCover}) {
    String cover = defaultCover ?? "";
    if (json['album'] != null && json['album']['image'] != null) {
      cover = json['album']['image']['large'] ?? cover;
    }

    return SonauraTrack(
      id: json['id']?.toString() ?? "0",
      title: json['title'] ?? "Título desconocido",
      artist: (json['artist'] != null) ? (json['artist']['name'] ?? "Artista") : "Artista",
      coverUrl: cover,
      quality: (json['maximum_bit_depth'] ?? 16) > 16 ? "HI-RES" : "CD",
      sampleRate: json['maximum_sampling_rate']?.toInt() ?? 44,
      bitDepth: json['maximum_bit_depth']?.toInt() ?? 16,
      isLocal: false,
    );
  }
}
