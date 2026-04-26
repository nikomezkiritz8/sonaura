import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  Future<bool> init() async {
    if (Platform.isLinux) return false;
    await Permission.microphone.request();

    // Configuración para voz natural
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.45); // Un poco más lento para ser elegante
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    
    // Intentar usar una voz específica si está disponible (Android)
    if (Platform.isAndroid) {
      await _tts.setEngine("com.google.android.tts");
    }
    return true;
  }

  Future hablar(String texto) async {
    if (Platform.isLinux) return;
    // Limpiamos el texto de etiquetas de búsqueda antes de hablar
    String limpiar = texto.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (limpiar.isNotEmpty) {
      await _tts.speak(limpiar);
    }
  }
}
