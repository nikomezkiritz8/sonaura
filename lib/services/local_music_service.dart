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
          tracks.add(SonauraTrack.fromLocalJson(item, serverUrl));
        }
      }
    } catch (e) { print("Error Vault: $e"); }
    return tracks;
  }
}
