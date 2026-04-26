import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SonauraAI {
  final String baseUrl = "http://100.72.167.73:11434/api/generate";
  static List<String> memoria = [];

  Future<String> preguntar(String prompt, {String? metadata}) async {
    try {
      final ioc = HttpClient();
      ioc.findProxy = (uri) => "DIRECT";
      final client = IOClient(ioc);

      String contextInfo = metadata != null ? "USUARIO ESCUCHANDO AHORA: $metadata." : "";

      String systemPrompt = """
      Eres SONAURA, una IA de audio High-End de élite. 
      $contextInfo
      
      INSTRUCCIONES:
      1. Tono sofisticado, breve y técnico.
      2. Si el usuario pide música, usa etiquetas: [SEARCH_TRACK: nombre] o [SEARCH_ALBUM: nombre].
      3. Si pide 'Insight' o 'Análisis', explica la calidad de grabación y masterización del disco actual.
      4. Responde SIEMPRE en español.
      
      Memoria reciente: ${memoria.length > 0 ? memoria.last : "Nueva sesión"}
      """;

      final response = await client.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          "model": "llama3", 
          "prompt": "$systemPrompt\nUsuario: $prompt\nSONAURA:",
          "stream": false,
          "options": {"temperature": 0.3}
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        String res = jsonDecode(response.body)['response'];
        if (memoria.length > 3) memoria.removeAt(0);
        memoria.add("U: $prompt - S: $res");
        return res;
      }
      return "Enlace neural inestable.";
    } catch (e) { return "Sonaura fuera de línea."; }
  }
}
