import 'package:flutter/material.dart';
import '../models/track_model.dart';
import '../services/qobuz_service.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class AlbumTracksScreen extends StatefulWidget {
  final String albumId;
  final String albumTitle;
  final String appId;
  final String appSecret;
  final String token;

  const AlbumTracksScreen({
    super.key, 
    required this.albumId, 
    required this.albumTitle, 
    required this.appId, 
    required this.appSecret, 
    required this.token
  });

  @override
  State<AlbumTracksScreen> createState() => _AlbumTracksScreenState();
}

class _AlbumTracksScreenState extends State<AlbumTracksScreen> {
  List<SonauraTrack> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() async {
    final qobuz = QobuzService(
      appId: widget.appId, 
      appSecret: widget.appSecret, 
      userAuthToken: widget.token
    );
    
    // Obtenemos las pistas del álbum (ya incluyen la carátula inyectada por el servicio)
    final tracks = await qobuz.getAlbumTracks(widget.albumId);
    
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

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
        title: Text(
          widget.albumTitle.toUpperCase(), 
          style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold, strokeWidth: 1))
        : ListView.builder(
            itemCount: _tracks.length,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemBuilder: (context, index) {
              final track = _tracks[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                leading: Text(
                  "${index + 1}".padLeft(2, '0'), 
                  style: const TextStyle(color: Colors.white10, fontSize: 14, fontFamily: 'monospace')
                ),
                // USAMOS cleanTitle: Adiós a "01 - " y ".flac"
                title: Text(
                  track.cleanTitle, 
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400)
                ),
                // INFO TÉCNICA: FLAC, BITS y KHZ
                subtitle: Text(
                  "FLAC | ${track.bitDepth}-BIT | ${track.sampleRate} KHZ", 
                  style: const TextStyle(color: SonauraColors.accentGold, fontSize: 9, letterSpacing: 1)
                ),
                trailing: const Icon(Icons.play_circle_outline, color: Colors.white12, size: 22),
                onTap: () {
                  // NAVEGACIÓN PRO: Enviamos el álbum entero como Playlist
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        playlist: _tracks,      // El álbum completo
                        initialIndex: index,    // La canción que tocaste
                        appId: widget.appId,
                        appSecret: widget.appSecret,
                        token: widget.token,
                      )
                    )
                  );
                },
              );
            },
          ),
    );
  }
}
