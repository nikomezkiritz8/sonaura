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
          tracks.add(SonauraTrack(
            id: "$serverUrl/file/${Uri.encodeFull(item['path'])}", 
            title: item['title'],
            artist: "Disco NIKO",
            // Ahora la URL de la carátula va a la ruta de extracción
            coverUrl: "$serverUrl/${Uri.encodeFull(item['cover'])}",
            quality: "FLAC HI-RES",
            sampleRate: 44, bitDepth: 16, isLocal: true,
          ));
        }
      }
    } catch (e) { print("Error: $e"); }
    return tracks;
  }
}
