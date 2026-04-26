import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/track_model.dart';
import '../services/qobuz_service.dart';
import 'sonaura_style.dart';

class PlayerScreen extends StatefulWidget {
  final SonauraTrack track;
  final String appId; final String appSecret; final String token;
  const PlayerScreen({super.key, required this.track, required this.appId, required this.appSecret, required this.token});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPlayerStateChanged.listen((s) => setState(() => _isPlaying = s == PlayerState.playing));
    _prepararAudio();
  }

  void _prepararAudio() async {
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);
    String? url = await qobuz.getHiResStreamUrl(widget.track.id);
    if (url != null) await _audioPlayer.play(UrlSource(url));
  }

  @override
  void dispose() { _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FONDO DIFUMINADO (BLUR EFFECT)
          Container(
            height: double.infinity, width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(widget.track.coverUrl), fit: BoxFit.cover),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent, elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  title: Text("${widget.track.quality} | ${widget.track.bitDepth}-BIT", style: const TextStyle(fontSize: 10, letterSpacing: 2, color: SonauraColors.accentGold)),
                  centerTitle: true,
                ),
                const Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 5)],
                    image: DecorationImage(image: NetworkImage(widget.track.coverUrl), fit: BoxFit.cover),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(widget.track.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                ),
                Text(widget.track.artist.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 4, color: Colors.white60)),
                const SizedBox(height: 30),
                Slider(
                  activeColor: Colors.white, inactiveColor: Colors.white10,
                  value: _position.inSeconds.toDouble(),
                  max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.shuffle, color: Colors.white24),
                    IconButton(icon: const Icon(Icons.skip_previous, size: 45, color: Colors.white), onPressed: () {}),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 80, color: Colors.white),
                      onPressed: () => _isPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, size: 45, color: Colors.white), onPressed: () {}),
                    const Icon(Icons.repeat, color: Colors.white24),
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

  String _formatDuration(Duration d) => "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}
