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
  final String appId;
  final String appSecret;
  final String token;

  const ChatSonaura({
    super.key, 
    required this.appId, 
    required this.appSecret, 
    required this.token
  });

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
  bool _autoListenEnabled = true; // Modo Google Home Activo

  @override
  void initState() {
    super.initState();
    _iniciarSonauraAutonoma();
  }

  // --- LÓGICA DE INICIO AUTÓNOMO ---
  void _iniciarSonauraAutonoma() async {
    await _voice.init();
    // Saludo inicial de cortesía
    setState(() {
      _messages.add({"role": "sonaura", "text": "Sistema Sonaura en línea. ¿Qué música deseas explorar hoy?"});
    });
    await _voice.hablar("Sistema Sonaura en línea. ¿Qué música deseas explorar hoy?");
    
    // Abrimos el micro por primera vez automáticamente
    _activarEscuchaModoHome();
  }

  // --- EL BUCLE DE ESCUCHA (GOOGLE HOME MODE) ---
  void _activarEscuchaModoHome() async {
    if (!mounted || _isTyping || _isListening) return;

    setState(() => _isListening = true);

    _voice.escuchar((res) {
      if (res.isNotEmpty) {
        setState(() {
          _isListening = false;
          _controller.text = res;
        });
        _procesarEntrada(res);
        _controller.clear();
      } else {
        // Si hay silencio absoluto, reiniciamos el micro tras un breve delay
        _reiniciarEscuchaTrasSilencio();
      }
    });
  }

  void _reiniciarEscuchaTrasSilencio() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_autoListenEnabled && !_isListening && !_isTyping) {
      _activarEscuchaModoHome();
    }
  }

  void _procesarEntrada(String texto) async {
    if (texto.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": texto});
      _isTyping = true;
      _isListening = false;
    });

    // 1. Preguntar a la IA
    String response = await _ai.preguntar(texto);

    if (!mounted) return;

    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    // 2. Sonaura habla (TTS)
    String textoParaHablar = response.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    await _voice.hablar(textoParaHablar);

    // 3. Ejecutar comandos de Qobuz/Biblioteca
    _analizarComandosIA(response, texto);

    // 4. VOLVER A ESCUCHAR AUTOMÁTICAMENTE (Bucle Google Home)
    if (_autoListenEnabled) {
      // Esperamos un momento para que el eco de los altavoces no interfiera
      Future.delayed(const Duration(milliseconds: 800), () {
        _activarEscuchaModoHome();
      });
    }
  }

  void _analizarComandosIA(String response, String originalText) {
    if (response.contains("[SEARCH_ALBUM:")) {
      String query = response.split("[SEARCH_ALBUM:")[1].split("]")[0].trim();
      _ejecutarBusquedaMusical(query, isAlbum: true);
    } else if (response.contains("[SEARCH_TRACK:")) {
      String query = response.split("[SEARCH_TRACK:")[1].split("]")[0].trim();
      _ejecutarBusquedaMusical(query, isAlbum: false);
    } else if (originalText.toLowerCase().contains("biblioteca") || originalText.toLowerCase().contains("mi música")) {
      _irABibliotecaLocal();
    }
  }

  void _irABibliotecaLocal() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryScreen(
      appId: widget.appId, appSecret: widget.appSecret, token: widget.token,
    )));
  }

  void _ejecutarBusquedaMusical(String queryRaw, {required bool isAlbum}) async {
    String query = queryRaw.replaceAll(RegExp(r'(busca|pon|reproduce|play|album)', caseSensitive: false), '').trim();
    final qobuz = QobuzService(appId: widget.appId, appSecret: widget.appSecret, userAuthToken: widget.token);

    try {
      if (isAlbum) {
        List<SonauraAlbum> albums = await qobuz.searchAlbums(query);
        if (albums.isNotEmpty && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumResultsScreen(
            albums: albums, appId: widget.appId, appSecret: widget.appSecret, token: widget.token,
          )));
        }
      } else {
        List<SonauraTrack> resultados = await qobuz.search(query);
        if (resultados.isNotEmpty && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsScreen(
            tracks: resultados, appId: widget.appId, appSecret: widget.appSecret, token: widget.token,
          )));
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white24),
          onPressed: () {
            setState(() => _autoListenEnabled = false); // Apagamos el bucle al salir
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            const Text("SONAURA HOME", 
                style: TextStyle(fontSize: 10, letterSpacing: 4, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_isListening ? "LISTENING..." : "AWAITING COMMAND", 
                style: TextStyle(fontSize: 7, color: _isListening ? Colors.red : Colors.white.withOpacity(0.2), letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_autoListenEnabled ? Icons.sensors : Icons.sensors_off, 
                color: _autoListenEnabled ? SonauraColors.accentGold : Colors.white10),
            onPressed: () => setState(() => _autoListenEnabled = !_autoListenEnabled),
          ),
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(isUser ? "YOU" : "SONAURA", 
                          style: TextStyle(fontSize: 8, color: SonauraColors.accentGold.withOpacity(0.5), letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        m["text"]!.replaceAll(RegExp(r'\[.*?\]'), '').trim(), 
                        style: TextStyle(
                          fontSize: 18, 
                          height: 1.5,
                          fontWeight: isUser ? FontWeight.w300 : FontWeight.w400, 
                          color: isUser ? Colors.white70 : Colors.white,
                          fontStyle: isUser ? FontStyle.normal : FontStyle.italic,
                        )
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isTyping) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
              child: LinearProgressIndicator(color: SonauraColors.accentGold, backgroundColor: Colors.transparent, minHeight: 1),
            ),

          // --- BARRA DE ESTADO DE ESCUCHA ---
          Container(
            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40, top: 20),
            decoration: const BoxDecoration(
              color: SonauraColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              children: [
                if (_isListening)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text("Sonaura te escucha...", style: TextStyle(color: SonauraColors.accentGold, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(hintText: "Escribe o habla...", border: InputBorder.none),
                        onSubmitted: (val) { _procesarEntrada(val); _controller.clear(); },
                      ),
                    ),
                    
                    // BOTÓN VISUAL DEL MODO HOME
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening ? Colors.red : SonauraColors.accentGold.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: _isListening ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15)] : [],
                      ),
                      child: Icon(
                        _isListening ? Icons.graphic_eq : Icons.mic_none, 
                        color: _isListening ? Colors.red : SonauraColors.accentGold, 
                        size: 28
                      ),
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
