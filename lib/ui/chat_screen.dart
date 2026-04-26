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
  bool _autoListenEnabled = true;

  @override
  void initState() {
    super.initState();
    _iniciarSonauraAutonoma();
  }

  void _iniciarSonauraAutonoma() async {
    await _voice.init();
    _agregarMensajeSonaura("Sistema Sonaura listo. Te escucho.");
    await _voice.hablar("Sistema Sonaura listo. Te escucho.");
    _activarEscuchaModoHome();
  }

  void _activarEscuchaModoHome() {
    if (!mounted || _isTyping || _voice.isListening || !_autoListenEnabled) return;
    setState(() => _isListening = true);

    _voice.escuchar(
      onResult: (texto) {
        setState(() => _controller.text = texto); // Feedback visual en tiempo real
      },
      onComplete: () {
        if (_controller.text.isNotEmpty) {
          String finalMsg = _controller.text;
          _controller.clear();
          _procesarEntrada(finalMsg);
        }
      }
    );
  }

  void _procesarEntrada(String texto) async {
    setState(() {
      _messages.add({"role": "user", "text": texto});
      _isTyping = true;
      _isListening = false;
    });

    String response = await _ai.preguntar(texto);
    if (!mounted) return;

    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    await _voice.hablar(response);
    _verificarComandos(response, texto);

    if (_autoListenEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () => _activarEscuchaModoHome());
    }
  }

  void _verificarComandos(String response, String promptOriginal) {
    if (response.contains("[SEARCH_ALBUM:")) {
      String q = response.split("[SEARCH_ALBUM:")[1].split("]")[0].trim();
      _buscar(q, true);
    } else if (response.contains("[SEARCH_TRACK:")) {
      String q = response.split("[SEARCH_TRACK:")[1].split("]")[0].trim();
      _buscar(q, false);
    } else if (promptOriginal.toLowerCase().contains("biblioteca")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    }
  }

  void _buscar(String q, bool isAlbum) async {
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);
    if (isAlbum) {
      var res = await qobuz.searchAlbums(q);
      if (res.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => AlbumResultsScreen(albums: res, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    } else {
      var res = await qobuz.search(q);
      if (res.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => SearchResultsScreen(tracks: res, appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));
    }
  }

  void _agregarMensajeSonaura(String t) => setState(() => _messages.add({"role": "sonaura", "text": t}));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("SONAURA HOME", style: TextStyle(fontSize: 10, letterSpacing: 4, color: SonauraColors.accentGold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.inventory_2_outlined, color: SonauraColors.accentGold), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)))),
          IconButton(icon: Icon(_autoListenEnabled ? Icons.sensors : Icons.sensors_off, color: _autoListenEnabled ? Colors.white30 : Colors.red), onPressed: () => setState(() => _autoListenEnabled = !_autoListenEnabled)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(30),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                bool isUser = m["role"] == "user";
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(isUser ? "TÚ" : "SONAURA", style: TextStyle(fontSize: 8, color: SonauraColors.accentGold.withOpacity(0.5))),
                      Text(m["text"]!.replaceAll(RegExp(r'\[.*?\]'), '').trim(), style: TextStyle(fontSize: 18, color: isUser ? Colors.white70 : Colors.white, fontStyle: isUser ? FontStyle.normal : FontStyle.italic)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(color: SonauraColors.accentGold, backgroundColor: Colors.transparent),
          Container(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 40),
            decoration: const BoxDecoration(color: SonauraColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              children: [
                if (_isListening) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Sonaura escuchando...", style: TextStyle(color: SonauraColors.accentGold, fontSize: 10))),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Escribe o habla...", border: InputBorder.none))),
                    Icon(_isListening ? Icons.graphic_eq : Icons.mic_none, color: _isListening ? Colors.red : SonauraColors.accentGold, size: 28),
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
