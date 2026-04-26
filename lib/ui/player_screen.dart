import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';
import '../services/qobuz_service.dart';
import '../services/sonaura_ai.dart';
import '../services/voice_service.dart';
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
  late AnimationController _spectrumController;
  final SonauraAI _ai = SonauraAI();
  final VoiceService _voice = VoiceService();
  bool _isShuffle = false;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _spectrumController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _prepararAudio();
  }

  void _prepararAudio() async {
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

  void _obtenerInsight() async {
    final track = widget.playlist[_currentIndex];
    String metadata = "${track.title} de ${track.artist} (${track.quality})";
    String response = await _ai.preguntar("Haz un análisis audiófilo de esta pieza.", metadata: metadata);
    _voice.hablar(response);
    
    showModalBottomSheet(
      context: context, backgroundColor: Colors.black90,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(padding: const EdgeInsets.all(30), child: SingleChildScrollView(child: Column(children: [
        const Text("SONAURA INSIGHT", style: TextStyle(color: SonauraColors.accentGold, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text(response, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, height: 1.6)),
      ]))),
    );
  }

  void _next() { setState(() { _currentIndex = _isShuffle ? math.Random().nextInt(widget.playlist.length) : (_currentIndex + 1) % widget.playlist.length; }); _prepararAudio(); }
  void _prev() { setState(() { _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length; }); _prepararAudio(); }

  @override
  void dispose() { _audioPlayer.dispose(); _spectrumController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final track = widget.playlist[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            height: double.infinity, width: double.infinity,
            decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(color: Colors.black.withOpacity(0.5))),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent, elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  title: Column(children: [
                    Text(track.isLocal ? "REMOTE VAULT" : "QOBUZ HI-RES", style: const TextStyle(fontSize: 7, color: Colors.white38)),
                    Text("FLAC | ${track.bitDepth}-BIT | ${track.sampleRate}KHZ", style: const TextStyle(fontSize: 9, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
                  ]),
                  actions: [IconButton(icon: const Icon(Icons.psychology, color: SonauraColors.accentGold), onPressed: _obtenerInsight)],
                ),
                const Spacer(),
                Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40)], image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                ),
                const Spacer(),
                
                // ESPECTRO FFT ANIMADO
                Container(height: 40, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: AnimatedBuilder(animation: _spectrumController, builder: (c, _) => CustomPaint(painter: SpectrumPainter(animationValue: _spectrumController.value, isPlaying: _audioPlayer.playing)))),

                const SizedBox(height: 20),
                Text(track.cleanTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                Text(track.artist.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 5, color: Colors.white38)),
                
                const SizedBox(height: 30),
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpectrumPainter extends CustomPainter {
  final double animationValue; final bool isPlaying;
  SpectrumPainter({required this.animationValue, required this.isPlaying});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = SonauraColors.accentGold.withOpacity(0.6)..style = PaintingStyle.fill;
    int bars = 35; double gap = 4.0; double w = (size.width - (bars * gap)) / bars;
    for (int i = 0; i < bars; i++) {
      double h = isPlaying ? (math.sin(animationValue * 15 + i) * 15).abs() + 3 : 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * (w + gap), size.height - h, w, h), const Radius.circular(2)), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => true;
}
