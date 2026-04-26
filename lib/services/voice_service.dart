import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  
  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (Platform.isLinux) return false;
    await Permission.microphone.request();
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);

    return await _speech.initialize(
      onStatus: (status) => print('Sonaura STT Status: $status'),
      onError: (error) => print('Sonaura STT Error: $error'),
    );
  }

  void escuchar({required Function(String) onResult, required Function() onComplete}) async {
    if (!_speech.isAvailable || _speech.isListening) return;

    await _speech.listen(
      onResult: (val) {
        onResult(val.recognizedWords);
        if (val.finalResult) {
          onComplete();
        }
      },
      localeId: 'es_ES',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2), // Detecta el silencio tras 2 segundos
      listenMode: ListenMode.confirmation,
    );
  }

  void detener() async => await _speech.stop();

  Future<void> hablar(String texto) async {
    if (Platform.isLinux) return;
    String limpiar = texto.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (limpiar.isEmpty) return;
    await _tts.speak(limpiar);
  }
}
