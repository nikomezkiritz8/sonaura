import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class LocalMusicService {
  final String serverUrl = "http://100.72.167.73:5050";

  Future<List<SonauraTrack>> getLocalTracks() async {
    List<SonauraTrack> tracks = [];
    try {
      final response = await http.get(Uri.parse('$serverUrl/list')).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        for (var item in data) {
          // Codificamos el path para que los espacios y caracteres especiales funcionen en la URL
          String encodedPath = Uri.encodeComponent(item['path']);
          
          tracks.add(SonauraTrack(
            id: "$serverUrl/file/$encodedPath", 
            title: item['title'],
            artist: "Disco NIKO",
            coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500",
            quality: item['path'].toString().toLowerCase().endsWith('.flac') ? "REMOTE FLAC" : "REMOTE AUDIO",
            sampleRate: 44, 
            bitDepth: 16, 
            isLocal: true,
          ));
        }
      }
    } catch (e) { 
      print("Sonaura Remote Vault Error: $e"); 
    }
    return tracks;
  }
}
