// Usamos importaciones condicionales o simplemente evitamos que rompa en Linux
import 'dart:io';
// Intentamos importar, pero si falla, usaremos una clase "Dummy"
// Nota: En Linux estas librerías darán error de compilación si no se manejan así
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  // Solo inicializamos si no es Linux, para evitar el crash
  dynamic _speech;
  dynamic _tts;

  bool get isLinux => Platform.isLinux;

  Future<bool> init() async {
    if (isLinux) return false;
    
    _speech = SpeechToText();
    _tts = FlutterTts();
    
    bool available = await _speech.initialize();
    await _tts.setLanguage("es-ES");
    return available;
  }

  void escuchar(Function(String) onResult) async {
    if (isLinux) return;
    await _speech.listen(onResult: (val) => onResult(val.recognizedWords));
  }

  void detener() {
    if (isLinux) return;
    _speech.stop();
  }

  Future hablar(String texto) async {
    if (isLinux) {
      print("TTS no disponible en Linux: $texto");
      return;
    }
    await _tts.speak(texto);
  }
}
