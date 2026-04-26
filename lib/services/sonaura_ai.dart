import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SonauraAI {
  final String baseUrl = "http://100.72.167.73:11434/api/generate";

  Future<String> preguntar(String prompt) async {
    try {
      final ioc = HttpClient();
      ioc.findProxy = (uri) => "DIRECT";
      final client = IOClient(ioc);

      // System Prompt Ultra-Refinado
      String systemPrompt = "Eres Sonaura, una IA audiófila. "
          "Si el usuario pide música, responde poéticamente y AL FINAL añade una etiqueta: "
          "[SEARCH_TRACK: nombre] para canciones o [SEARCH_ALBUM: nombre] para álbumes. "
          "Ejemplo: 'Excelente elección. Aquí tienes el álbum de Dermot Kennedy. [SEARCH_ALBUM: Dermot Kennedy Sonder]'";

      final response = await client.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          "model": "llama3", 
          "prompt": "$systemPrompt User: $prompt",
          "stream": false
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      }
      return "Hubo un error en el enlace neural.";
    } catch (e) {
      return "Sonaura fuera de línea.";
    }
  }
}
