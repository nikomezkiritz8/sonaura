import 'dart:ui';
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
      String? url;

      if (widget.track.isLocal) {
        // --- STREAMING DESDE TU DISCO NIKO (VÍA FLASK + TAILSCALE) ---
        // En este caso, track.id ya contiene la URL http://100.72.167.73:5050/file/...
        url = widget.track.id;
      } else {
        // --- STREAMING DESDE QOBUZ ---
        final qobuz = QobuzService(
          appId: widget.appId,
          appSecret: widget.appSecret,
          userAuthToken: widget.token
        );
        url = await qobuz.getHiResStreamUrl(widget.track.id);
      }

      if (url != null) {
        print("Sonaura Loading: $url");
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ),
        );
        _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Sonaura Playback Error: $e");
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
          // 1. FONDO DIFUMINADO DINÁMICO (ESTILO APPLE MUSIC)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.track.coverUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Difuminado ultra-profundo
              child: Container(
                color: Colors.black.withOpacity(0.4), // Capa para que resalte el contenido
              ),
            ),
          ),

          // 2. INTERFAZ DE CONTROL
          SafeArea(
            child: Column(
              children: [
                // Header
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
                        widget.track.isLocal ? "NIKO VAULT STREAMING" : "QOBUZ HI-RES AUDIO", 
                        style: const TextStyle(fontSize: 7, letterSpacing: 2.5, color: Colors.white38)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.track.quality} | ${widget.track.bitDepth}-BIT", 
                        style: const TextStyle(fontSize: 10, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),

                const Spacer(),

                // CARÁTULA FLOTANTE
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 50,
                          spreadRadius: 2,
                          offset: const Offset(0, 25),
                        )
                      ],
                      image: DecorationImage(
                        image: NetworkImage(widget.track.coverUrl), 
                        fit: BoxFit.cover
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // INFO PISTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        widget.track.title, 
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: -0.5)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.track.artist.toUpperCase(), 
                        style: const TextStyle(fontSize: 12, letterSpacing: 4, color: Colors.white54, fontWeight: FontWeight.bold)
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
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbColor: Colors.white,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white12,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: position.inSeconds.toDouble(),
                              max: total.inSeconds.toDouble() > 0 ? total.inSeconds.toDouble() : 1.0,
                              onChanged: (val) => _audioPlayer.seek(Duration(seconds: val.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position), style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
                                Text(_formatDuration(total), style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // BOTONES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.shuffle, color: Colors.white24, size: 24),
                    IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 48)
                    ),
                    
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final playing = playerState?.playing;
                        final processingState = playerState?.processingState;

                        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                          return const SizedBox(width: 85, height: 85, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5));
                        }
                        return IconButton(
                          iconSize: 95,
                          icon: Icon(playing == true ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: Colors.white),
                          onPressed: playing == true ? _audioPlayer.pause : _audioPlayer.play,
                        );
                      },
                    ),

                    IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48)
                    ),
                    const Icon(Icons.repeat, color: Colors.white24, size: 24),
                  ],
                ),
                const SizedBox(height: 50),
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
