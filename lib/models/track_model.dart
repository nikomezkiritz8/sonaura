class SonauraTrack {
  final String id;
  final String title;
  final String artist;
  String coverUrl;
  final String quality;
  final int sampleRate;
  final int bitDepth;
  final bool isLocal;

  SonauraTrack({
    required this.id, required this.title, required this.artist, 
    required this.coverUrl, required this.quality, required this.sampleRate, 
    required this.bitDepth, this.isLocal = false,
  });

  // Limpia el nombre: quita .flac, .mp3 y el "01 - " del principio
  String get cleanTitle {
    return title
        .replaceAll(RegExp(r'\.(flac|mp3)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\d+\s*[-\.\s]*'), '')
        .trim();
  }

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
      sampleRate: (json['maximum_sampling_rate']?.toDouble() ?? 44.1).toInt(),
      bitDepth: json['maximum_bit_depth']?.toInt() ?? 16,
      isLocal: false,
    );
  }

  factory SonauraTrack.fromLocalJson(Map<String, dynamic> json, String serverUrl) {
    return SonauraTrack(
      id: "$serverUrl/file/${Uri.encodeFull(json['path'])}",
      title: json['title'] ?? "Archivo Local",
      artist: "Local Vault",
      coverUrl: "$serverUrl/${Uri.encodeFull(json['cover'])}",
      quality: (json['bit_depth'] ?? 16) > 16 ? "HI-RES" : "LOSSLESS",
      sampleRate: json['sample_rate']?.toInt() ?? 44,
      bitDepth: json['bit_depth']?.toInt() ?? 16,
      isLocal: true,
    );
  }
}
