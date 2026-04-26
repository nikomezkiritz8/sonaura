import 'package:flutter/material.dart';
import '../services/sonaura_ai.dart';
import '../services/voice_service.dart';
import '../services/qobuz_service.dart'; 
import '../models/track_model.dart';
import '../models/album_model.dart'; 
import 'sonaura_style.dart';
import 'search_results_screen.dart'; 
import 'album_results_screen.dart'; 
import 'library_screen.dart';

class ChatSonaura extends StatefulWidget {
  final String appId; final String appSecret; final String token;
  const ChatSonaura({super.key, required this.appId, required this.appSecret, required this.token});
  @override
  State<ChatSonaura> createState() => _ChatSonauraState();
}

class _ChatSonauraState extends State<ChatSonaura> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final SonauraAI _ai = SonauraAI();
  final VoiceService _voice = VoiceService();
  bool _isTyping = false;
  bool _isListening = false;
  bool _autoListen = true;

  @override
  void initState() { super.initState(); _boot(); }

  void _boot() async {
    await _voice.init();
    _addMsg("Sistema Sonaura listo. Di mi nombre o escríbeme.");
    _voice.hablar("Sistema Sonaura listo. Di mi nombre o escríbeme.");
    _startLoop();
  }

  void _startLoop() {
    if (!mounted || _isTyping || !_autoListen) return;
    setState(() => _isListening = true);
    _voice.escuchar(
      onResult: (t) => setState(() => _controller.text = t),
      onComplete: () {
        String val = _controller.text.trim();
        if (val.toLowerCase().contains("sonaura") || val.toLowerCase().contains("so now")) {
           _controller.clear(); _handle(val);
        } else {
           _controller.clear(); _startLoop();
        }
      }
    );
  }

  void _handle(String text) async {
    if (text.isEmpty) return;
    _voice.detenerEscucha();
    setState(() { _messages.add({"role": "user", "text": text}); _isTyping = true; _isListening = false; });
    String res = await _ai.preguntar(text);
    if (!mounted) return;
    setState(() { _messages.add({"role": "sonaura", "text": res}); _isTyping = false; });
    await _voice.hablar(res);
    _exec(res, text);
    if (_autoListen) _startLoop();
  }

  void _exec(String res, String text) {
    if (res.contains("[SEARCH_ALBUM:")) { _search(res.split("[SEARCH_ALBUM:")[1].split("]")[0], true); }
    else if (res.contains("[SEARCH_TRACK:")) { _search(res.split("[SEARCH_TRACK:")[1].split("]")[0], false); }
    else if (text.toLowerCase().contains("biblioteca")) { _navLib(); }
  }

  void _search(String qRaw, bool isAlbum) async {
    String q = qRaw.replaceAll(RegExp(r'(discografía de|álbumes de|pon a|busca|reproduce)', caseSensitive: false), '').trim();
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);
    if (isAlbum) {
      var albums = await qobuz.searchAlbums(q);
      if (albums.isEmpty && q.contains(" ")) albums = await qobuz.searchAlbums(q.split(" ").first);
      if (albums.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => AlbumResultsScreen(albums: albums, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    } else {
      var tracks = await qobuz.search(q);
      if (tracks.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => SearchResultsScreen(tracks: tracks, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    }
  }

  void _navLib() => Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
  void _addMsg(String t) => setState(() => _messages.add({"role": "sonaura", "text": t}));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("SONAURA INTELLIGENCE", style: TextStyle(fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold, color: SonauraColors.accentGold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.inventory_2_outlined, color: SonauraColors.accentGold, size: 22), onPressed: _navLib)],
      ),
      body: Column(
        children: [
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(30), itemCount: _messages.length, itemBuilder: (c, i) {
            final m = _messages[i]; bool isU = m["role"] == "user";
            return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: isU ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
              Text(isU ? "TÚ" : "SONAURA", style: TextStyle(fontSize: 7, color: SonauraColors.accentGold.withOpacity(0.5))),
              Text(m["text"]!.replaceAll(RegExp(r'\[.*?\]'), '').trim(), style: TextStyle(fontSize: 18, color: isU ? Colors.white70 : Colors.white, fontStyle: isU ? FontStyle.normal : FontStyle.italic)),
            ]));
          })),
          if (_isTyping) const LinearProgressIndicator(color: SonauraColors.accentGold, backgroundColor: Colors.transparent),
          Container(padding: const EdgeInsets.fromLTRB(30, 10, 30, 40), decoration: const BoxDecoration(color: SonauraColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(40))), child: Row(children: [
            Expanded(child: TextField(controller: _controller, onSubmitted: _handle, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _isListening ? "Escuchando..." : "Escribe o di 'Sonaura'...", border: InputBorder.none))),
            IconButton(icon: const Icon(Icons.volume_off, color: Colors.white12), onPressed: () => _voice.detenerHabla()),
            Icon(_isListening ? Icons.graphic_eq : Icons.mic_none, color: _isListening ? Colors.red : SonauraColors.accentGold, size: 28),
          ]))
        ],
      ),
    );
  }
}
