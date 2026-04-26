import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyric_model.dart';

class LyricsService {
  Future<SonauraLyrics?> getLyrics(String artist, String title) async {
    // Limpiamos el título de "Remaster", "Live", etc para que la base de datos lo encuentre
    String cleanTitle = title.split(' (')[0].split(' - ')[0].trim();
    
    try {
      final url = Uri.parse('https://lrclib.net/api/get?artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(cleanTitle)}');
      print("Sonaura: Buscando letras para $artist - $cleanTitle");
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? lrc = data['syncedLyrics'] ?? data['plainLyrics'];
        if (lrc != null) return SonauraLyrics.parse(lrc);
      }
    } catch (e) { print("Error letras: $e"); }
    return null;
  }
}
