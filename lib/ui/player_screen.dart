import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';
import '../services/qobuz_service.dart';
import 'sonaura_style.dart';

class PlayerScreen extends StatefulWidget {
  final List<SonauraTrack> playlist;
  final int initialIndex;
  final String appId; final String appSecret; final String token;

  const PlayerScreen({super.key, required this.playlist, required this.initialIndex, required this.appId, required this.appSecret, required this.token});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  late AnimationController _bgController;
  bool _isShuffle = false;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);

    // AUTO-NEXT: Al terminar una canción, salta a la siguiente
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) { _next(); }
    });

    _prepararAudio();
  }

  void _prepararAudio() async {
    if (!mounted) return;
    setState(() => _isBuffering = true);
    final track = widget.playlist[_currentIndex];
    try {
      String? url = track.isLocal ? track.id : await QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token).getHiResStreamUrl(track.id);
      if (url != null) {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url), headers: {'User-Agent': 'Sonaura-Audiophile/1.0'}));
        _audioPlayer.play();
      }
    } catch (e) { debugPrint("Error: $e"); }
    if (mounted) setState(() => _isBuffering = false);
  }

  void _next() {
    setState(() {
      _currentIndex = _isShuffle ? math.Random().nextInt(widget.playlist.length) : (_currentIndex + 1) % widget.playlist.length;
    });
    _prepararAudio();
  }

  void _prev() {
    setState(() { _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length; });
    _prepararAudio();
  }

  @override
  void dispose() { _audioPlayer.dispose(); _bgController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final track = widget.playlist[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FONDO ANIMADO
          AnimatedBuilder(
            animation: _bgController,
            builder: (c, child) => Transform.scale(
              scale: 1.2 + (_bgController.value * 0.2),
              child: Container(
                decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(color: Colors.black.withOpacity(0.4))),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent, elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  title: Column(children: [
                    Text(track.isLocal ? "REMOTE VAULT" : "QOBUZ HI-RES", style: const TextStyle(fontSize: 7, color: Colors.white38, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text("FLAC | ${track.bitDepth}-BIT | ${track.sampleRate}KHZ", style: const TextStyle(fontSize: 10, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
                  ]),
                  centerTitle: true,
                ),
                const Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8, height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 40)], image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(children: [
                    Text(track.cleanTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    const Text("SONAURA HIGH-END AUDIO", style: TextStyle(fontSize: 9, letterSpacing: 4, color: Colors.white24)),
                  ]),
                ),
                const SizedBox(height: 40),
                StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero; final dur = _audioPlayer.duration ?? Duration.zero;
                    return Column(children: [
                      Slider(activeColor: Colors.white, inactiveColor: Colors.white10, value: pos.inSeconds.toDouble(), max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0, onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt()))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white24, fontSize: 10)), Text("${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white24, fontSize: 10))]))
                    ]);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: Icon(Icons.shuffle, color: _isShuffle ? SonauraColors.accentGold : Colors.white24), onPressed: () => setState(() => _isShuffle = !_isShuffle)),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: _prev),
                    _isBuffering ? const CircularProgressIndicator(color: SonauraColors.accentGold) : IconButton(icon: Icon(_audioPlayer.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 85, color: Colors.white), onPressed: () => _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play()),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: _next),
                    const Icon(Icons.repeat, color: Colors.white24),
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
}
