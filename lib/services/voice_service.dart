import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<bool> init() async {
    if (Platform.isLinux) return false;

    // Pedir permiso de micrófono explícitamente
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print("Sonaura: Permiso de micro denegado por el usuario");
      return false;
    }

    return await _speech.initialize(
      onStatus: (status) => print('Sonaura Voice Status: $status'),
      onError: (error) => print('Sonaura Voice Error: $error'),
    );
  }

  void escuchar(Function(String) onResult) async {
    if (!_speech.isAvailable || _speech.isListening) return;

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: 'es_ES',
      cancelOnError: true,
      partialResults: true,
    );
  }

  void detener() async {
    await _speech.stop();
  }

  Future hablar(String texto) async {
    if (Platform.isLinux) return;
    await _tts.setLanguage("es-ES");
    await _tts.speak(texto);
  }
}
