import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  Future<bool> init() async {
    if (Platform.isLinux) return false;

    // Pedir permisos de micro
    await Permission.microphone.request();

    // Configurar Voz Natural (TTS)
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.45); 
    await _tts.setPitch(1.0);
    if (Platform.isAndroid) {
      await _tts.setEngine("com.google.android.tts");
    }

    // Inicializar Escucha (STT)
    return await _speech.initialize(
      onStatus: (status) => print('Sonaura STT Status: $status'),
      onError: (error) => print('Sonaura STT Error: $error'),
    );
  }

  // ESTA ES LA FUNCIÓN QUE FALTABA
  void escuchar(Function(String) onResult) async {
    if (!_speech.isAvailable || _speech.isListening) return;
    await _speech.listen(
      onResult: (val) => onResult(val.recognizedWords),
      localeId: 'es_ES',
    );
  }

  // ESTA ES LA OTRA FUNCIÓN QUE FALTABA
  void detener() async {
    await _speech.stop();
  }

  Future hablar(String texto) async {
    if (Platform.isLinux) return;
    // Limpiamos etiquetas de IA antes de hablar
    String limpiar = texto.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (limpiar.isNotEmpty) {
      await _tts.speak(limpiar);
    }
  }
}
