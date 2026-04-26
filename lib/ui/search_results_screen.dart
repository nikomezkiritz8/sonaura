import 'package:flutter/material.dart';
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<SonauraTrack> tracks;
  
  // Necesitamos recibir las credenciales para pasarlas al reproductor
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
        iconTheme: const IconThemeData(color: SonauraColors.accentGold, size: 20),
        title: const Text(
          "GALERÍA DE ALTA RESOLUCIÓN", 
          style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white38)
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,           // 2 columnas como en las apps de diseño
          childAspectRatio: 0.65,      // Espacio para la carátula + textos
          crossAxisSpacing: 25,
          mainAxisSpacing: 25,
        ),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          
          return GestureDetector(
            onTap: () {
              // Al pulsar, vamos al reproductor con todos los datos necesarios
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    track: track,
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
                // Carátula con sombra y bordes finos
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: SonauraColors.surface,
                      borderRadius: BorderRadius.circular(2),
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
                
                // Título de la pista (Estilo elegante)
                Text(
                  track.title, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500, 
                    fontSize: 15, 
                    color: Colors.white,
                    fontStyle: FontStyle.italic
                  )
                ),
                
                const SizedBox(height: 4),
                
                // Artista (En mayúsculas minimalistas)
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
                
                // Etiqueta técnica (Lo que nos diferencia de Apple Music)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: SonauraColors.accentGold.withOpacity(0.5), width: 0.5),
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
