import 'package:flutter/material.dart';
import '../services/local_music_service.dart';
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class LibraryScreen extends StatelessWidget {
  final String appId;
  final String appSecret;
  final String token;

  const LibraryScreen({
    super.key,
    required this.appId,
    required this.appSecret,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "LOCAL VAULT", 
          style: TextStyle(fontSize: 10, letterSpacing: 3, color: SonauraColors.accentGold)
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SonauraTrack>>(
        future: LocalMusicService().getLocalTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold, strokeWidth: 1));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No se encontraron archivos en /NIKO/MUSIKK", 
              style: TextStyle(color: Colors.white24, fontSize: 12))
            );
          }

          final tracks = snapshot.data!;

          return ListView.builder(
            itemCount: tracks.length,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            itemBuilder: (context, index) {
              final track = tracks[index];
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: SonauraColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.music_note, color: SonauraColors.accentGold, size: 20),
                ),
                // Usamos cleanTitle para que en la lista tampoco salga el .flac ni el 01
                title: Text(
                  track.cleanTitle, 
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                ),
                subtitle: Text(
                  "${track.quality} | SOURCE: NIKO", 
                  style: const TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1)
                ),
                trailing: const Icon(Icons.more_vert, color: Colors.white10, size: 18),
                onTap: () {
                  // NAVEGACIÓN PRO: Enviamos la lista completa y la posición actual
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        playlist: tracks,      // Pasamos toda la carpeta MUSIKK
                        initialIndex: index,   // Canción específica pulsada
                        appId: appId,
                        appSecret: appSecret,
                        token: token,
                      )
                    )
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
