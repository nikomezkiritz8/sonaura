import 'package:flutter/material.dart';
import '../services/local_music_service.dart';
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class LibraryScreen extends StatelessWidget {
  final String appId; final String appSecret; final String token;
  const LibraryScreen({super.key, required this.appId, required this.appSecret, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("LOCAL VAULT", style: TextStyle(fontSize: 10, letterSpacing: 3, color: SonauraColors.accentGold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SonauraTrack>>(
        future: LocalMusicService().getLocalTracks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold));
          final tracks = snapshot.data!;
          return ListView.builder(
            itemCount: tracks.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: const Icon(Icons.audio_file_outlined, color: SonauraColors.accentGold),
                title: Text(track.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text("FLAC | DISCO NIKO", style: TextStyle(color: Colors.white24, fontSize: 9)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(track: track, appId: appId, appSecret: appSecret, token: token))),
              );
            },
          );
        },
      ),
    );
  }
}
