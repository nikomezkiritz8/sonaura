import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  
  // Estado para saber si Sonaura está hablando
  bool _estaHablando = false;
  bool get estaHablando => _estaHablando;

  Future<bool> init() async {
    if (Platform.isLinux) return false;

    // 1. Solicitar permisos de micrófono de forma imperativa
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;

    // 2. Configurar motor de Voz Natural (TTS)
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.48); // Velocidad elegante, no robótica
    await _tts.setPitch(1.0);       // Tono natural
    await _tts.setVolume(1.0);

    if (Platform.isAndroid) {
      await _tts.setEngine("com.google.android.tts"); // Motor de alta calidad de Google
    }

    // 3. Configurar la sincronización de fin de habla (Vital para modo Home)
    await _tts.awaitSpeakCompletion(true); 

    // 4. Inicializar motor de Escucha (STT)
    return await _speech.initialize(
      onStatus: (status) => print('Sonaura STT Status: $status'),
      onError: (error) => print('Sonaura STT Error: $error'),
    );
  }

  // --- ESCUCHA ACTIVA ---
  void escuchar(Function(String) onResult) async {
    // Si ya está escuchando o el motor no está listo, ignoramos
    if (!_speech.isAvailable || _speech.isListening) return;

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
        }
      },
      localeId: 'es_ES',
      listenFor: const Duration(seconds: 15), // Ventana de escucha larga
      pauseFor: const Duration(seconds: 3),   // Tiempo de silencio para cortar
      cancelOnError: true,
      partialResults: false, // Solo queremos la frase completa para la IA
    );
  }

  void detener() async {
    await _speech.stop();
  }

  // --- HABLA SINCRONIZADA (MODO GOOGLE HOME) ---
  Future<void> hablar(String texto) async {
    if (Platform.isLinux) return;

    // Limpiamos etiquetas técnicas de la IA para que no las mencione
    String limpiar = texto.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (limpiar.isEmpty) return;

    try {
      _estaHablando = true;
      
      // Detenemos el micro un segundo por seguridad antes de hablar
      await _speech.stop();

      // Sonaura habla y ESPERA a terminar (gracias a awaitSpeakCompletion)
      await _tts.speak(limpiar);
      
      // Pequeño margen extra para el eco de la habitación
      await Future.delayed(const Duration(milliseconds: 500));
      
      _estaHablando = false;
    } catch (e) {
      print("Error en TTS: $e");
      _estaHablando = false;
    }
  }

  // Comprobar si el micro está libre
  bool get puedeEscuchar => !_speech.isListening && !_estaHablando;
}
