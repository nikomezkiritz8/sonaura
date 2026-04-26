import 'package:flutter/material.dart';
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<SonauraTrack> tracks;
  final String appId;
  final String appSecret;
  final String token;

  const SearchResultsScreen({
    super.key, 
    required this.tracks,
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
          "GALERÍA DE ALTA RESOLUCIÓN", 
          style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white38)
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,           
          childAspectRatio: 0.65,      
          crossAxisSpacing: 25,
          mainAxisSpacing: 25,
        ),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          
          return GestureDetector(
            onTap: () {
              // NAVEGACIÓN PRO: Ahora enviamos toda la lista de búsqueda (playlist)
              // y el índice de la canción que el usuario ha tocado.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    playlist: tracks,      // La lista completa de resultados
                    initialIndex: index,   // La posición actual
                    appId: appId,
                    appSecret: appSecret,
                    token: token,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carátula con sombra audiófila
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: SonauraColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                      image: DecorationImage(
                        image: NetworkImage(track.coverUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                // TÍTULO LIMPIO (Sin 01 ni .flac)
                Text(
                  track.cleanTitle, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500, 
                    fontSize: 14, 
                    color: Colors.white,
                    fontStyle: FontStyle.italic
                  )
                ),
                
                const SizedBox(height: 4),
                
                // Artista
                Text(
                  track.artist.toUpperCase(), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38, 
                    fontSize: 10, 
                    letterSpacing: 1.5
                  )
                ),
                
                const SizedBox(height: 8),
                
                // Badge técnico de resolución
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: SonauraColors.accentGold.withOpacity(0.4), width: 0.5),
                  ),
                  child: Text(
                    "${track.quality} | ${track.bitDepth}-BIT", 
                    style: const TextStyle(
                      color: SonauraColors.accentGold, 
                      fontSize: 8, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1
                    )
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
