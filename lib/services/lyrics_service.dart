import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyric_model.dart';

class LyricsService {
  // Usamos LRCLIB, una base de datos gratuita y abierta para audiófilos
  Future<SonauraLyrics?> getLyrics(String artist, String title) async {
    try {
      final url = Uri.parse('https://lrclib.net/api/get?artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(title)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? syncedLyrics = data['syncedLyrics']; // Buscamos la versión sincronizada
        if (syncedLyrics != null) {
          return SonauraLyrics.parse(syncedLyrics);
        }
      }
    } catch (e) {
      print("Sonaura Lyrics Error: $e");
    }
    return null;
  }
}
