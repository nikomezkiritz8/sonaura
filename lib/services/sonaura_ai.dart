import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SonauraAI {
  // USAMOS TU IP DE TAILSCALE: 100.72.167.73
  // Esto permite que el móvil conecte con tu PC desde cualquier red.
  final String baseUrl = "http://100.72.167.73:11434/api/generate";

  Future<String> preguntar(String prompt) async {
    try {
      final ioc = HttpClient();
      ioc.findProxy = (uri) => "DIRECT";
      final client = IOClient(ioc);

      final response = await client.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          "model": "llama3", 
          "prompt": "Eres Sonaura, una IA audiófila. Responde de forma muy breve y sofisticada: $prompt",
          "stream": false
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      }
      return "Error de enlace neural (${response.statusCode})";
    } catch (e) {
      return "Sonaura no detecta tu servidor Tailscale (100.72.167.73).";
    }
  }
}
