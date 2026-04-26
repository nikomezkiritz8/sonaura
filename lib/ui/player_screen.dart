import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';
import '../services/qobuz_service.dart';
import 'sonaura_style.dart';

class PlayerScreen extends StatefulWidget {
  final SonauraTrack track;
  final String appId;
  final String appSecret;
  final String token;

  const PlayerScreen({
    super.key, 
    required this.track, 
    required this.appId, 
    required this.appSecret, 
    required this.token
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _prepararAudio();
  }

  void _prepararAudio() async {
    try {
      if (widget.track.isLocal) {
        // --- REPRODUCCIÓN DE ARCHIVO LOCAL (TU DISCO NIKO) ---
        await _audioPlayer.setAudioSource(
          AudioSource.file(widget.track.id), // El ID es la ruta del archivo
        );
      } else {
        // --- REPRODUCCIÓN DESDE QOBUZ (STREAMING) ---
        final qobuz = QobuzService(
          appId: widget.appId,
          appSecret: widget.appSecret,
          userAuthToken: widget.token
        );

        String? url = await qobuz.getHiResStreamUrl(widget.track.id);
        
        if (url != null) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              headers: {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            ),
          );
        }
      }
      
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Sonaura Error de Audio: $e");
    }

    if (mounted) {
      setState(() => _isBuffering = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO DIFUMINADO (ESTILO APPLE MUSIC)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.track.isLocal 
                    ? const AssetImage('assets/images/default_cover.png') as ImageProvider // O una imagen local
                    : NetworkImage(widget.track.coverUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), // Difuminado profundo
              child: Container(
                color: Colors.black.withOpacity(0.5), // Capa de oscuridad para legibilidad
              ),
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                // Cabecera minimalista
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 35),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Column(
                    children: [
                      Text(
                        widget.track.isLocal ? "BIBLIOTECA LOCAL" : "REPRODUCIENDO DESDE QOBUZ", 
                        style: const TextStyle(fontSize: 8, letterSpacing: 2, color: Colors.white38)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.track.quality} | ${widget.track.bitDepth}-BIT | ${widget.track.sampleRate} KHZ", 
                        style: const TextStyle(fontSize: 10, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),

                const Spacer(),

                // CARÁTULA FLOTANTE
                Center(
                  child: Hero(
                    tag: widget.track.id,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 20),
                          )
                        ],
                        image: DecorationImage(
                          image: NetworkImage(widget.track.coverUrl), 
                          fit: BoxFit.cover
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // TÍTULO Y ARTISTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        widget.track.title, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: Colors.white)
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.track.artist.toUpperCase(), 
                        style: const TextStyle(fontSize: 12, letterSpacing: 5, color: Colors.white54, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BARRA DE PROGRESO
                StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = _audioPlayer.duration ?? Duration.zero;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbColor: Colors.white,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white10,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: position.inSeconds.toDouble(),
                              max: total.inSeconds.toDouble() > 0 ? total.inSeconds.toDouble() : 1.0,
                              onChanged: (val) => _audioPlayer.seek(Duration(seconds: val.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position), style: const TextStyle(fontSize: 10, color: Colors.white24, fontFamily: 'monospace')),
                                Text(_formatDuration(total), style: const TextStyle(fontSize: 10, color: Colors.white24, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // CONTROLES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.shuffle, color: Colors.white10, size: 22),
                    IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 45)
                    ),
                    
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final playing = playerState?.playing;
                        final processingState = playerState?.processingState;

                        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                          return const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                        }
                        return IconButton(
                          iconSize: 90,
                          icon: Icon(playing == true ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: Colors.white),
                          onPressed: playing == true ? _audioPlayer.pause : _audioPlayer.play,
                        );
                      },
                    ),

                    IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 45)
                    ),
                    const Icon(Icons.repeat, color: Colors.white10, size: 22),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
