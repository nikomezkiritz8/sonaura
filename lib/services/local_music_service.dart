import 'dart:io';
import '../models/track_model.dart';

class LocalMusicService {
  final String localPath = "/run/media/koila1998/NIKO/MUSIKK";

  Future<List<SonauraTrack>> getLocalTracks() async {
    List<SonauraTrack> tracks = [];
    try {
      final directory = Directory(localPath);
      if (await directory.exists()) {
        final files = directory.listSync(recursive: true)
            .where((file) => file.path.endsWith('.flac') || file.path.endsWith('.mp3'))
            .toList();

        for (var file in files) {
          tracks.add(SonauraTrack(
            id: file.path,
            title: file.path.split('/').last.replaceAll(RegExp(r'\.(flac|mp3)'), ''),
            artist: "Biblioteca Local",
            coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500",
            quality: "LOCAL FLAC",
            sampleRate: 44, bitDepth: 16, isLocal: true,
          ));
        }
      }
    } catch (e) { print("Error Local: $e"); }
    return tracks;
  }
}
