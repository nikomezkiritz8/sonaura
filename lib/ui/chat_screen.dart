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
  bool _isActivated = false; // ¿Ha escuchado "Sonaura"?
  bool _autoListen = true;

  @override
  void initState() {
    super.initState();
    _bootSonaura();
  }

  void _bootSonaura() async {
    await _voice.init();
    _speakAndDisplay("Sistema Sonaura listo. Di 'Hey Sonaura' para activarme.");
    _startListeningLoop();
  }

  void _startListeningLoop() {
    if (!mounted || _isTyping || !_autoListen) return;
    
    _voice.escuchar(
      onResult: (t) {
        setState(() => _controller.text = t);
        // LÓGICA WAKE WORD
        if (t.toLowerCase().contains("sonaura") && !_isActivated) {
          setState(() => _isActivated = true);
        }
      },
      onComplete: () {
        if (_controller.text.isNotEmpty) {
          String val = _controller.text;
          _controller.clear();
          
          if (_isActivated || val.toLowerCase().contains("sonaura")) {
             setState(() => _isActivated = false);
             _handleInput(val);
          } else {
             // Si habló pero no dijo Sonaura, volvemos a escuchar en silencio
             _startListeningLoop();
          }
        } else {
          Future.delayed(const Duration(milliseconds: 500), () => _startListeningLoop());
        }
      }
    );
  }

  void _handleInput(String text) async {
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isTyping = true;
    });

    String response = await _ai.preguntar(text);
    if (!mounted) return;

    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    await _voice.hablar(response);
    _execCommands(response, text);

    if (_autoListen) _startListeningLoop();
  }

  void _execCommands(String response, String text) {
    if (response.contains("[SEARCH_ALBUM:")) {
      _execSearch(response.split("[SEARCH_ALBUM:")[1].split("]")[0], true);
    } else if (response.contains("[SEARCH_TRACK:")) {
      _execSearch(response.split("[SEARCH_TRACK:")[1].split("]")[0], false);
    } else if (text.toLowerCase().contains("biblioteca")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    }
  }

  void _execSearch(String q, bool isAlbum) async {
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);
    if (isAlbum) {
      var res = await qobuz.searchAlbums(q.trim());
      if (res.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => AlbumResultsScreen(albums: res, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    } else {
      var res = await qobuz.search(q.trim());
      if (res.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => SearchResultsScreen(tracks: res, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    }
  }

  void _speakAndDisplay(String t) {
    setState(() => _messages.add({"role": "sonaura", "text": t}));
    _voice.hablar(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(_isActivated ? "ESCUCHANDO..." : "MODO VIGILANTE", style: TextStyle(fontSize: 10, letterSpacing: 4, color: _isActivated ? Colors.red : SonauraColors.accentGold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.volume_off, color: Colors.white24, size: 20), onPressed: () => _voice.detenerHabla()),
          IconButton(icon: Icon(Icons.inventory_2_outlined, color: SonauraColors.accentGold, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                bool isUser = m["role"] == "user";
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(isUser ? "USUARIO" : "SONAURA", style: TextStyle(fontSize: 8, color: SonauraColors.accentGold.withOpacity(0.5))),
                      Text(m["text"]!.replaceAll(RegExp(r'\[.*?\]'), '').trim(), style: TextStyle(fontSize: 18, color: isUser ? Colors.white70 : Colors.white, fontStyle: isUser ? FontStyle.normal : FontStyle.italic)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(color: SonauraColors.accentGold, backgroundColor: Colors.transparent),
          
          Container(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
            decoration: const BoxDecoration(color: SonauraColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _isActivated ? "Te escucho..." : "Di 'Sonaura'...", border: InputBorder.none))),
                    
                    // BOTÓN VISUAL WAKE WORD
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: _isActivated ? Colors.red : Colors.white10),
                        boxShadow: _isActivated ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20)] : []
                      ),
                      child: Icon(_isActivated ? Icons.graphic_eq : Icons.mic_none, color: _isActivated ? Colors.red : Colors.white24, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
