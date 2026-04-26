import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<bool> init() async {
    if (Platform.isLinux) return false;
    
    // Inicializa el motor de voz
    bool available = await _speech.initialize(
      onStatus: (status) => print('Sonaura Voice Status: $status'),
      onError: (errorNotification) => print('Sonaura Voice Error: $errorNotification'),
    );
    
    await _tts.setLanguage("es-ES");
    await _tts.setPitch(0.9);
    return available;
  }

  void escuchar(Function(String) onResult) async {
    // Comprobamos permisos antes de escuchar
    var hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      await _speech.initialize();
    }

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
        }
      },
      localeId: 'es_ES',
    );
  }

  void detener() async {
    await _speech.stop();
  }

  Future hablar(String texto) async {
    if (Platform.isLinux) return;
    await _tts.speak(texto);
  }
}
