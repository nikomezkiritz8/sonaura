import 'package:flutter/material.dart';
import '../services/sonaura_ai.dart';
import '../services/voice_service.dart';
import '../services/qobuz_service.dart'; 
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'search_results_screen.dart'; 

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

  @override
  void initState() {
    super.initState();
    _inicializarServicios();
  }

  void _inicializarServicios() async {
    // Inicializamos el motor de voz al arrancar
    await _voice.init();
  }

  // Lógica para enviar texto a Ollama
  void _procesarEntrada(String texto) async {
    if (texto.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": texto});
      _isTyping = true;
    });

    String response = await _ai.preguntar(texto);

    if (!mounted) return;

    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    // Sonaura responde con voz
    _voice.hablar(response);

    // Lógica de búsqueda musical
    String promptLower = texto.toLowerCase();
    List<String> keywords = ["busca", "pon", "reproduce", "encuentra", "escuchar", "play"];
    if (keywords.any((key) => promptLower.contains(key))) {
      _ejecutarBusquedaMusical(texto);
    }
  }

  void _ejecutarBusquedaMusical(String texto) async {
    String query = texto
        .replaceAll(RegExp(r'(busca|pon|reproduce|escuchar|encuentra|oír|quiero escuchar|toca|play)'), '')
        .trim();

    if (query.isEmpty) return;

    final qobuz = QobuzService(
      appId: widget.appId,
      appSecret: widget.appSecret,
      userAuthToken: widget.token,
    );

    try {
      List<SonauraTrack> resultados = await qobuz.search(query);
      if (resultados.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsScreen(
              tracks: resultados,
              appId: widget.appId,
              appSecret: widget.appSecret,
              token: widget.token,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error Qobuz: $e");
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("SONAURA INTELLIGENCE", 
                style: TextStyle(fontSize: 10, letterSpacing: 4, color: SonauraColors.accentGold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("NEURAL LINK ACTIVE", 
                style: TextStyle(fontSize: 7, color: _isListening ? Colors.red : Colors.white.withOpacity(0.2), letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(isUser ? "USER_INPUT" : "SONAURA_RESPONSE", 
                          style: TextStyle(fontSize: 8, color: SonauraColors.accentGold.withOpacity(0.5), letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text(
                        m["text"]!, 
                        style: TextStyle(
                          fontSize: 18, 
                          height: 1.6,
                          fontWeight: isUser ? FontWeight.w300 : FontWeight.w400, 
                          color: isUser ? Colors.white60 : Colors.white,
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

          // ÁREA DE ENTRADA
          Container(
            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40, top: 20),
            decoration: const BoxDecoration(
              color: SonauraColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
                    decoration: InputDecoration(
                      hintText: _isListening ? "Escuchando..." : "Escribe o pulsa el micro...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 14),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) { 
                      _procesarEntrada(val); 
                      _controller.clear(); 
                    },
                  ),
                ),
                
                // BOTÓN DE MICRÓFONO REPARADO
                GestureDetector(
                  onLongPressStart: (_) async {
                    // Vibración táctil para confirmar inicio
                    setState(() => _isListening = true);
                    _voice.escuchar((res) {
                      setState(() => _controller.text = res);
                    });
                  },
                  onLongPressEnd: (_) async {
                    setState(() => _isListening = false);
                    _voice.detener();
                    
                    // Pequeña espera para que el motor termine de procesar la última palabra
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    if (_controller.text.isNotEmpty) {
                      _procesarEntrada(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: AnimatedScale(
                    scale: _isListening ? 1.4 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red.withOpacity(0.2) : Colors.transparent,
                        border: Border.all(
                          color: _isListening ? Colors.red : SonauraColors.accentGold.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.graphic_eq : Icons.mic_none, 
                        color: _isListening ? Colors.red : SonauraColors.accentGold, 
                        size: 26
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
