import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class LocalMusicService {
  final String serverUrl = "http://100.72.167.73:5050";

  Future<List<SonauraTrack>> getLocalTracks() async {
    List<SonauraTrack> tracks = [];
    try {
      final response = await http.get(Uri.parse('$serverUrl/list'));
      
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        for (var item in data) {
          String fullAudioUrl = "$serverUrl/file/${Uri.encodeFull(item['path'])}";
          
          // Si el servidor encontró carátula, usamos esa URL, si no, una por defecto elegante
          String coverUrl = item['cover'] != "" 
              ? "$serverUrl/${Uri.encodeFull(item['cover'])}"
              : "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500";
          
          tracks.add(SonauraTrack(
            id: fullAudioUrl, 
            title: item['title'],
            artist: "Local Vault",
            coverUrl: coverUrl,
            quality: item['path'].toString().toLowerCase().endsWith('.flac') ? "HI-RES" : "AUDIO",
            sampleRate: 44, 
            bitDepth: 16, 
            isLocal: true,
          ));
        }
      }
    } catch (e) { print("Error cargando carátulas locales: $e"); }
    return tracks;
  }
}
