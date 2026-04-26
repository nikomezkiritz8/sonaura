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

  const AlbumTracksScreen({super.key, required this.albumId, required this.albumTitle, required this.appId, required this.appSecret, required this.token});

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
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);
    final tracks = await qobuz.getAlbumTracks(widget.albumId);
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.albumTitle.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold))
        : ListView.builder(
            itemCount: _tracks.length,
            itemBuilder: (context, index) {
              final track = _tracks[index];
              return ListTile(
                leading: Text("${index + 1}", style: const TextStyle(color: Colors.white24, fontSize: 12)),
                title: Text(track.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: Text("${track.bitDepth}-BIT | ${track.sampleRate}KHZ", style: const TextStyle(color: SonauraColors.accentGold, fontSize: 9)),
                trailing: const Icon(Icons.play_arrow_outlined, color: SonauraColors.accentGold, size: 20),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(
                    track: track,
                    appId: widget.appId,
                    appSecret: widget.appSecret,
                    token: widget.token,
                  )));
                },
              );
            },
          ),
    );
  }
}
