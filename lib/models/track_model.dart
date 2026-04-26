class SonauraTrack {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
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

  factory SonauraTrack.fromJson(Map<String, dynamic> json) {
    // Buscador de artista ultra-robusto
    String artistName = "Artista desconocido";
    if (json['artist'] != null && json['artist']['name'] != null) {
      artistName = json['artist']['name'];
    } else if (json['performer'] != null && json['performer']['name'] != null) {
      artistName = json['performer']['name'];
    } else if (json['album'] != null && json['album']['artist'] != null) {
      artistName = json['album']['artist']['name'] ?? "Artista desconocido";
    }

    return SonauraTrack(
      id: json['id']?.toString() ?? "0",
      title: json['title'] ?? "Título desconocido",
      artist: artistName,
      coverUrl: (json['album'] != null && json['album']['image'] != null) 
          ? (json['album']['image']['large'] ?? "https://www.qobuz.com/static/images/covers/front/500/0825646122449_500.jpg")
          : "https://www.qobuz.com/static/images/covers/front/500/0825646122449_500.jpg",
      quality: (json['maximum_bit_depth'] ?? 16) > 16 ? "HI-RES" : "CD",
      sampleRate: json['maximum_sampling_rate']?.toInt() ?? 44,
      bitDepth: json['maximum_bit_depth']?.toInt() ?? 16,
    );
  }
}
