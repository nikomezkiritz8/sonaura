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
      extendBodyBehindAppBar: true, // Para que el contenido suba hasta arriba
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NIKO VAULT",
          style: TextStyle(
            fontSize: 12, 
            letterSpacing: 5, 
            fontWeight: FontWeight.w900, 
            color: SonauraColors.accentGold
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SonauraTrack>>(
        future: LocalMusicService().getLocalTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold, strokeWidth: 1));
          }
          
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text("Vault vacío o disco no montado", style: TextStyle(color: Colors.white24)));
          }

          return CustomScrollView(
            slivers: [
              // HEADER DECORATIVO
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 120, left: 30, right: 30, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tu Colección Privada", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                      const SizedBox(height: 10),
                      Text(
                        "${tracks.length} PISTAS EN ALTA FIDELIDAD",
                        style: const TextStyle(color: SonauraColors.accentGold, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 0.5, color: Colors.white10),
                    ],
                  ),
                ),
              ),
              // GRID DE CARÁTULAS (Lo que lo hace visual)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(
                            playlist: tracks,
                            initialIndex: index,
                            appId: appId,
                            appSecret: appSecret,
                            token: token,
                          )));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CARÁTULA CON SOMBRA Y PROFUNDIDAD
                            Expanded(
                              child: Hero(
                                tag: track.id,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: SonauraColors.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                    image: DecorationImage(
                                      image: NetworkImage(track.coverUrl),
                                      fit: BoxFit.cover,
                                      // Filtro por si la imagen falla
                                      onError: (e, s) => const Icon(Icons.music_note, color: Colors.white10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // TEXTO LIMPIO Y ELEGANTE
                            Text(
                              track.cleanTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text("FLAC", style: TextStyle(color: SonauraColors.accentGold, fontSize: 8, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "SOURCE: NIKO",
                                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 8, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
