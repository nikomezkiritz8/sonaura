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
  late AnimationController _visualizerController; // Para la onda spectral
  late AnimationController _bgController;         // Para el fondo que se mueve
  final SonauraAI _ai = SonauraAI();
  final VoiceService _voice = VoiceService();
  bool _isShuffle = false;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    
    // Controlador para la onda spectral (más rápido)
    _visualizerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    
    // Controlador para el fondo (más lento y suave)
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);

    // Auto-Next cuando termina la canción
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

  // FUNCIÓN DEL CEREBRO (IA INSIGHT)
  void _obtenerInsight() async {
    final track = widget.playlist[_currentIndex];
    String metadata = "${track.title} de ${track.artist} (${track.quality})";
    
    // Mostrar cargador mientras la RTX 4060 piensa
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sonaura analizando la pieza..."), duration: Duration(seconds: 2)));

    String response = await _ai.preguntar("Haz un análisis audiófilo y técnico de esta canción.", metadata: metadata);
    _voice.hablar(response);
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.psychology, color: SonauraColors.accentGold, size: 40),
              const SizedBox(height: 10),
              const Text("SONAURA INSIGHT", style: TextStyle(color: SonauraColors.accentGold, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(response, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, height: 1.6)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _next() { setState(() { _currentIndex = _isShuffle ? math.Random().nextInt(widget.playlist.length) : (_currentIndex + 1) % widget.playlist.length; }); _prepararAudio(); }
  void _prev() { setState(() { _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length; }); _prepararAudio(); }

  @override
  void dispose() { 
    _audioPlayer.dispose(); 
    _visualizerController.dispose(); 
    _bgController.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.playlist[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO DIFUMINADO QUE SE MUEVE
          AnimatedBuilder(
            animation: _bgController,
            builder: (c, child) => Transform.scale(
              scale: 1.2 + (_bgController.value * 0.15),
              child: Container(
                decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(color: Colors.black.withOpacity(0.4))),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // 2. APPBAR CON EL CEREBRO
                AppBar(
                  backgroundColor: Colors.transparent, elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  title: Column(children: [
                    Text(track.isLocal ? "NIKO VAULT" : "QOBUZ HI-RES", style: const TextStyle(fontSize: 7, color: Colors.white38, letterSpacing: 2)),
                    Text("${track.quality} | ${track.bitDepth}-BIT | ${track.sampleRate}KHZ", style: const TextStyle(fontSize: 9, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.psychology, color: SonauraColors.accentGold, size: 28), 
                      onPressed: _obtenerInsight
                    ),
                    const SizedBox(width: 10),
                  ],
                  centerTitle: true,
                ),
                
                const Spacer(),
                
                // 3. CARÁTULA
                Hero(
                  tag: track.id,
                  child: Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 40)], image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                  ),
                ),
                
                const Spacer(),
                
                // 4. ONDA SPECTRAL DORADA
                Container(
                  height: 45, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: AnimatedBuilder(
                    animation: _visualizerController, 
                    builder: (c, _) => CustomPaint(
                      painter: SpectrumPainter(
                        animationValue: _visualizerController.value, 
                        isPlaying: _audioPlayer.playing
                      )
                    )
                  ),
                ),

                const SizedBox(height: 20),
                
                // 5. TEXTOS LIMPIOS
                Text(track.cleanTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                const Text("SONAURA HIGH-END AUDIO", style: TextStyle(fontSize: 8, letterSpacing: 4, color: Colors.white24)),
                
                const SizedBox(height: 40),
                
                // 6. PROGRESO
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

                // 7. CONTROLES
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

// --- PINTOR DE LA ONDA SPECTRAL ---
class SpectrumPainter extends CustomPainter {
  final double animationValue; final bool isPlaying;
  SpectrumPainter({required this.animationValue, required this.isPlaying});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = SonauraColors.accentGold.withOpacity(0.6)..style = PaintingStyle.fill;
    int bars = 30; double gap = 5.0; double w = (size.width - (bars * gap)) / bars;
    for (int i = 0; i < bars; i++) {
      // Movimiento aleatorio pero sincronizado
      double h = isPlaying ? (math.sin(animationValue * 10 + i) * 15).abs() + 4 : 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * (w + gap), size.height - h, w, h), const Radius.circular(3)), paint);
    }
  }
  @override
  bool shouldRepaint(SpectrumPainter old) => true;
}
