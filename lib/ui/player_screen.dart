import 'dart:ui';
import 'dart:math';
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

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  bool _isShuffle = false;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
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

  void _playNext() {
    setState(() {
      if (_isShuffle) { _currentIndex = Random().nextInt(widget.playlist.length); }
      else { _currentIndex = (_currentIndex + 1) % widget.playlist.length; }
    });
    _prepararAudio();
  }

  void _playPrevious() {
    setState(() { _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length; });
    _prepararAudio();
  }

  @override
  void dispose() { _audioPlayer.dispose(); super.dispose(); }

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
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.black.withOpacity(0.4))),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent, elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  title: Column(children: [
                    Text(track.isLocal ? "NIKO VAULT" : "QOBUZ HI-RES", style: const TextStyle(fontSize: 7, color: Colors.white38)),
                    Text("FLAC | ${track.bitDepth}-BIT | ${track.sampleRate}KHZ", style: const TextStyle(fontSize: 10, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
                  ]),
                  centerTitle: true,
                ),
                const Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8, height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 40)], image: DecorationImage(image: NetworkImage(track.coverUrl), fit: BoxFit.cover)),
                ),
                const Spacer(),
                Text(track.cleanTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                Text(track.artist.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 4, color: Colors.white54)),
                const SizedBox(height: 30),
                StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = _audioPlayer.duration ?? Duration.zero;
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
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: _playPrevious),
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        if (_isBuffering) return const CircularProgressIndicator(color: Colors.white);
                        return IconButton(icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 85, color: Colors.white), onPressed: () => playing ? _audioPlayer.pause() : _audioPlayer.play());
                      },
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: _playNext),
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
