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
  bool _isActivated = false; 
  bool _autoListen = true;

  @override
  void initState() {
    super.initState();
    _bootSonaura();
  }

  void _bootSonaura() async {
    await _voice.init();
    _agregarMensajeSonaura("Sonaura online. Puedes escribirme o decir mi nombre.");
    await _voice.hablar("Sonaura online. Puedes escribirme o decir mi nombre.");
    _startListeningLoop();
  }

  void _startListeningLoop() {
    if (!mounted || _isTyping || !_autoListen) return;
    setState(() => _isListening = true);

    _voice.escuchar(
      onResult: (t) => setState(() => _controller.text = t),
      onComplete: () {
        String val = _controller.text.trim();
        if (val.isNotEmpty) {
          // Si detecta "Sonaura" o variaciones similares se activa
          if (val.toLowerCase().contains("sonaura") || val.toLowerCase().contains("so now")) {
             _controller.clear();
             _handleInput(val);
          } else {
             _controller.clear();
             _startListeningLoop();
          }
        } else {
          Future.delayed(const Duration(milliseconds: 500), () => _startListeningLoop());
        }
      }
    );
  }

  // FUNCIÓN MAESTRA DE ENTRADA (Teclado y Voz)
  void _handleInput(String text) async {
    if (text.isEmpty) return;
    
    // Detenemos la escucha mientras la IA procesa
    _voice.detenerEscucha();
    
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isTyping = true;
      _isListening = false;
    });

    String response = await _ai.preguntar(text);
    if (!mounted) return;

    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    await _voice.hablar(response);
    _execCommands(response, text);

    // Reiniciar escucha si el modo automático está puesto
    if (_autoListen) _startListeningLoop();
  }

  void _execCommands(String response, String text) {
    if (response.contains("[SEARCH_ALBUM:")) {
      _execSearch(response.split("[SEARCH_ALBUM:")[1].split("]")[0], true);
    } else if (response.contains("[SEARCH_TRACK:")) {
      _execSearch(response.split("[SEARCH_TRACK:")[1].split("]")[0], false);
    } else if (text.toLowerCase().contains("biblioteca") || text.toLowerCase().contains("mi música")) {
      _navToLibrary();
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

  void _navToLibrary() => Navigator.push(context, MaterialPageRoute(builder: (c) => LibraryScreen(appId: widget.appId, appSecret: widget.appSecret, token: widget.token)));

  void _agregarMensajeSonaura(String t) => setState(() => _messages.add({"role": "sonaura", "text": t}));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("SONAURA INTELLIGENCE", style: TextStyle(fontSize: 10, letterSpacing: 5, fontWeight: FontWeight.bold, color: SonauraColors.accentGold)),
        centerTitle: true,
        actions: [
          // BOTÓN DE BIBLIOTECA (RESTAURADO)
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: SonauraColors.accentGold, size: 22), 
            onPressed: _navToLibrary,
            tooltip: "Mi Vault Local",
          ),
          const SizedBox(width: 10),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(isUser ? "TÚ" : "SONAURA", style: TextStyle(fontSize: 7, color: SonauraColors.accentGold.withOpacity(0.5), letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text(m["text"]!.replaceAll(RegExp(r'\[.*?\]'), '').trim(), 
                           style: TextStyle(fontSize: 18, height: 1.6, color: isUser ? Colors.white60 : Colors.white, fontStyle: isUser ? FontStyle.normal : FontStyle.italic)),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
                    // FUNCIÓN: ENVIAR CON ENTER
                    onSubmitted: (val) {
                      _handleInput(val);
                      _controller.clear();
                    },
                    decoration: InputDecoration(
                      hintText: _isListening ? "Te escucho..." : "Escribe o di 'Sonaura'...",
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: Colors.white10),
                    ),
                  ),
                ),
                
                // BOTÓN SILENCIAR HABLA
                IconButton(
                  icon: const Icon(Icons.volume_off, color: Colors.white12),
                  onPressed: () => _voice.detenerHabla(),
                ),

                const SizedBox(width: 10),

                // ICONO DINÁMICO MICRO
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: _isListening ? Colors.red : SonauraColors.accentGold.withOpacity(0.1)),
                  ),
                  child: Icon(_isListening ? Icons.graphic_eq : Icons.mic_none, color: _isListening ? Colors.red : SonauraColors.accentGold, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
