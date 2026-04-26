import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SonauraAI {
  final String baseUrl = "http://127.0.0.1:11434/api/generate";

  Future<String> preguntar(String prompt) async {
    try {
      // ESTO FUERZA A IGNORAR EL PROXY DE TU SISTEMA
      final ioc = HttpClient();
      ioc.findProxy = (uri) => "DIRECT"; // Obliga a conexión directa
      final client = IOClient(ioc);

      final response = await client.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          "model": "llama3", 
          "prompt": "Eres Sonaura, una inteligencia artificial audiófila de alta gama. Responde SIEMPRE en español, de forma muy breve, elegante y poética: $prompt",
          "stream": false
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      }
      return "Sonaura ha encontrado un error técnico (${response.statusCode})";
    } catch (e) {
      return "Sonaura está en modo offline. Por favor, inicia Ollama.";
    }
  }
}
