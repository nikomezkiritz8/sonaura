import 'dart:io';
import 'package:flutter/material.dart';
import 'ui/sonaura_style.dart';
import 'ui/chat_screen.dart';

// --- CLASE PARA SOLUCIONAR EL ERROR DEL PROXY EN LINUX ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) => "DIRECT"; // Obliga a la app a ignorar el proxy del sistema
  }
}

void main() async {
  // 1. Aseguramos que los motores de Flutter estén listos antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Aplicamos el parche de red para evitar el error de "Stream Error" y el Proxy
  HttpOverrides.global = MyHttpOverrides();

  runApp(const SonauraApp());
}

class SonauraApp extends StatelessWidget {
  const SonauraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sonaura Hi-Res',
      theme: SonauraTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de texto para capturar tus credenciales de Qobuz
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _appSecretController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _appIdController.dispose();
    _appSecretController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _entrarASonaura() {
    // Verificación de seguridad
    if (_appIdController.text.isEmpty || 
        _appSecretController.text.isEmpty || 
        _tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: SonauraColors.accentGold,
          content: Text("Introduce tus credenciales de Qobuz para activar el motor Hi-Res", 
          style: TextStyle(color: Colors.black))),
      );
      return;
    }

    // Navegación hacia el núcleo de Sonaura (Chat e IA)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSonaura(
          appId: _appIdController.text,
          appSecret: _appSecretController.text,
          token: _tokenController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // LADO IZQUIERDO: Branding Audiófilo (Desktop)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(60),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.blur_on, color: SonauraColors.accentGold, size: 28),
                        const SizedBox(width: 15),
                        Text("Sonaura", style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("La música,\ntal y como fue\ngrabada.", 
                             style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 30),
                        Text("Streaming bit-perfect, Hi-Res hasta 24-bit / 192 kHz.\nConversa con Sonaura AI sobre la esencia del sonido.",
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8)),
                      ],
                    ),
                    const Text(". FLAC  . 24-BIT  . 192 KHZ  . BIT-PERFECT", 
                         style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // LADO DERECHO: Formulario de Acceso
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * (isDesktop ? 0.12 : 0.08)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("01 — AUTHENTICATION", 
                      style: TextStyle(color: SonauraColors.accentGold, fontSize: 10, letterSpacing: 3)),
                  const SizedBox(height: 15),
                  const Text("Bienvenido al sonido puro", 
                             style: TextStyle(fontSize: 28, fontWeight: FontWeight.w200, letterSpacing: -0.5)),
                  const SizedBox(height: 50),
                  
                  _SonauraInput(label: "QOBUZ APP ID", controller: _appIdController),
                  _SonauraInput(label: "QOBUZ APP SECRET", controller: _appSecretController, isPassword: true),
                  _SonauraInput(label: "QOBUZ USER TOKEN", controller: _tokenController),
                  
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SonauraColors.accentGold,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                      ),
                      onPressed: _entrarASonaura,
                      child: const Text("INICIAR EXPERIENCIA", 
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Sonaura se conectará directamente a los servidores de Qobuz evitando intermediarios.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10, height: 1.5),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SonauraInput extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;

  const _SonauraInput({
    required this.label, 
    required this.controller,
    this.isPassword = false
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        cursorColor: SonauraColors.accentGold,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SonauraColors.accentGold)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
