import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SonauraColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color accentGold = Color(0xFFC5A073); // El tono canela/oro de tu imagen
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color surface = Color(0xFF161616);
}

class SonauraTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SonauraColors.background,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
      bodyMedium: GoogleFonts.inter(
        color: SonauraColors.textSecondary,
        fontSize: 14,
        letterSpacing: 1.2,
      ),
      labelLarge: GoogleFonts.inter(
        color: SonauraColors.accentGold,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    ),
  );
}
