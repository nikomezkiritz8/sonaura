import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SonauraAI {
  final String baseUrl = "http://100.72.167.73:11434/api/generate";
  // Memoria a corto plazo para que sea más lista
  List<String> memoria = [];

  Future<String> preguntar(String prompt) async {
    try {
      final ioc = HttpClient();
      ioc.findProxy = (uri) => "DIRECT";
      final client = IOClient(ioc);

      // System Prompt de nivel Ingeniero Audiófilo
      String instruction = """
      Eres SONAURA, la inteligencia artificial de un sistema de audio High-End.
      Tu conocimiento sobre música, masterización y discografías es infinito.
      
      REGLAS DE ORO:
      1. Tono: Sofisticado, técnico, breve y extremadamente culto.
      2. Si el usuario pide un artista o género sin especificar, busca sus mejores pistas: [SEARCH_TRACK: nombre].
      3. Si el usuario pide un disco o 'álbum', usa: [SEARCH_ALBUM: nombre].
      4. Si el usuario pide su música o biblioteca, usa: [OPEN_LIBRARY].
      5. IMPORTANTE: Extrae EXACTAMENTE el nombre del artista o canción. No incluyas 'por favor' o 'puedes poner'.
      
      Contexto actual: ${memoria.length > 0 ? memoria.last : "Inicio de sesión"}
      """;

      final response = await client.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          "model": "llama3", 
          "prompt": "$instruction\nUsuario: $prompt\nSONAURA:",
          "stream": false,
          "options": {
            "temperature": 0.3, // Menos creatividad, más precisión
            "top_p": 0.9
          }
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        String resText = jsonDecode(response.body)['response'];
        // Guardamos en memoria para que la siguiente vez sea más lista
        if (memoria.length > 5) memoria.removeAt(0);
        memoria.add("Usuario dijo: $prompt. Sonaura respondió: $resText");
        return resText;
      }
      return "Error de enlace neural.";
    } catch (e) {
      return "Sonaura fuera de línea.";
    }
  }
}
