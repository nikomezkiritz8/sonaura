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

  @override
  void initState() {
    super.initState();
    _voice.init();
    print("Sonaura Chat: Iniciado con Token: ${widget.token.substring(0, 5)}...");
  }

  void _procesarEntrada(String texto) async {
    if (texto.isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "text": texto});
      _isTyping = true;
    });

    // 1. Obtener respuesta de Ollama
    String response = await _ai.preguntar(texto);

    if (!mounted) return;
    setState(() {
      _messages.add({"role": "sonaura", "text": response});
      _isTyping = false;
    });

    _voice.hablar(response);

    // 2. LÓGICA DE ACTIVACIÓN DE BÚSQUEDA
    String promptLower = texto.toLowerCase();
    if (promptLower.contains("busca") || promptLower.contains("pon") || promptLower.contains("reproduce")) {
      print("Sonaura: Detectada intención de búsqueda en: '$texto'");
      _ejecutarBusquedaMusical(texto);
    }
  }

  void _ejecutarBusquedaMusical(String texto) async {
    String query = texto
        .replaceAll(RegExp(r'(busca|pon|reproduce|escuchar|encuentra|play)', caseSensitive: false), '')
        .trim();

    print("Sonaura: Consultando Qobuz por -> '$query'");

    final qobuz = QobuzService(
      appId: widget.appId,
      appSecret: widget.appSecret,
      userAuthToken: widget.token,
    );

    List<SonauraTrack> resultados = await qobuz.search(query);

    if (resultados.isNotEmpty) {
      print("Sonaura: ¡Éxito! Encontradas ${resultados.length} canciones. Navegando...");
      if (!mounted) return;
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
    } else {
      print("Sonaura: La búsqueda no devolvió resultados. Revisa tus credenciales.");
      setState(() {
        _messages.add({"role": "sonaura", "text": "Lo siento, no he encontrado nada en el catálogo con esos datos."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("SONAURA INTELLIGENCE", style: TextStyle(fontSize: 10, letterSpacing: 3, color: SonauraColors.accentGold)),
        centerTitle: true,
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
                      Text(isUser ? "USER" : "SONAURA", style: const TextStyle(fontSize: 8, color: SonauraColors.accentGold)),
                      const SizedBox(height: 5),
                      Text(m["text"]!, style: TextStyle(fontSize: 16, color: isUser ? Colors.white70 : Colors.white, fontStyle: isUser ? FontStyle.normal : FontStyle.italic)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(color: SonauraColors.accentGold, backgroundColor: Colors.transparent),
          Container(
            padding: const EdgeInsets.all(20),
            color: SonauraColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Escribe 'Busca Daft Punk'...", border: InputBorder.none),
                    onSubmitted: (val) { _procesarEntrada(val); _controller.clear(); },
                  ),
                ),
                const Icon(Icons.mic_none, color: SonauraColors.accentGold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
