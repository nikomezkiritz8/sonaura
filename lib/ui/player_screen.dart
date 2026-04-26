import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Escuchar cambios de posición y duración
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPlayerStateChanged.listen((s) => setState(() => _isPlaying = s == PlayerState.playing));

    _prepararAudio();
  }

  void _prepararAudio() async {
    final qobuz = QobuzService(
      appId: widget.appId,
      appSecret: widget.appSecret,
      userAuthToken: widget.token
    );

    String? url = await qobuz.getHiResStreamUrl(widget.track.id);
    print("SONAURA_AUDIO_URL: $url");

    if (url != null) {
      try {
        // En Audioplayers para Linux, usamos Source de URL directa
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        print("Sonaura Audio Error: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("SONAURA HI-RES PLAYER", style: TextStyle(fontSize: 8, letterSpacing: 2, color: Colors.white24)),
            Text("${widget.track.quality} | ${widget.track.bitDepth}-BIT", 
                 style: const TextStyle(fontSize: 10, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
                image: DecorationImage(image: NetworkImage(widget.track.coverUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(widget.track.title, style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic)),
          Text(widget.track.artist.toUpperCase(), style: const TextStyle(letterSpacing: 4, color: Colors.white38, fontSize: 12)),
          
          const SizedBox(height: 40),
          
          Slider(
            activeColor: SonauraColors.accentGold,
            inactiveColor: Colors.white10,
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
            onChanged: (value) => _audioPlayer.seek(Duration(seconds: value.toInt())),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),

          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.shuffle, color: Colors.white10),
              IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
              _isLoading 
                ? const CircularProgressIndicator(color: SonauraColors.accentGold)
                : IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                    color: SonauraColors.accentGold, size: 70),
                    onPressed: () => _isPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
                  ),
              IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
              const Icon(Icons.repeat, color: Colors.white10),
            ],
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
