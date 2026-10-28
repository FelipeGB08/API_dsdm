import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema escuro para o catálogo, inspirado em interfaces de streaming.
abstract final class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFB9F43A);
  static const Color accentSecondary = Color(0xFFFF4D8D);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB3B3B3);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(
      base.textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: background,
        secondary: accentSecondary,
        onSecondary: background,
        surface: surface,
        onSurface: textPrimary,
        error: Color(0xFFFF6B6B),
        onError: background,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF303030)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          disabledBackgroundColor: const Color(0xFF454545),
          disabledForegroundColor: textSecondary,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: accent,
        secondarySelectedColor: accentSecondary,
        labelStyle: const TextStyle(color: textPrimary),
        side: const BorderSide(color: Color(0xFF343434)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      dividerColor: const Color(0xFF303030),
    );
  }
}
