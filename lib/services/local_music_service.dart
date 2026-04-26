import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/track_model.dart';

class LocalMusicService {
  // IP de tu PC con Tailscale
  final String serverUrl = "http://100.72.167.73:5050";

  // Cliente que ignora proxies para asegurar que el móvil vea al PC
  http.Client get _directClient {
    final ioc = HttpClient();
    ioc.findProxy = (uri) => "DIRECT";
    return IOClient(ioc);
  }

  Future<List<SonauraTrack>> getLocalTracks() async {
    List<SonauraTrack> tracks = [];
    try {
      print("🔍 Sonaura: Conectando al Vault en $serverUrl...");
      
      // Pedimos la lista al servidor Python (CachyOS)
      final response = await _directClient.get(Uri.parse('$serverUrl/list'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        
        for (var item in data) {
          // --- CLAVE PARA LAS LETRAS ---
          // Usamos fromLocalJson para que el objeto 'track' tenga:
          // 1. El artista real (para buscar la letra)
          // 2. El título real (sin .flac)
          // 3. Bits y kHz reales
          tracks.add(SonauraTrack.fromLocalJson(item, serverUrl));
        }
        print("✅ Sonaura Vault: ${tracks.length} canciones cargadas con metadatos.");
      } else {
        print("❌ Error del servidor: ${response.statusCode}");
      }
    } catch (e) { 
      print("❌ Sonaura Remote Vault Connection Error: $e"); 
    }
    
    return tracks;
  }
}
