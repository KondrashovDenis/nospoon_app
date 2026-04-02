/// CRT темы для Spoon Messenger

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SpoonTheme { phosphorGreen, amber, paperWhite, cyan }

class AppTheme {
  static const themes = {
    SpoonTheme.phosphorGreen: _ThemeColors(
      background: Color(0xFF0D0D0D),
      primary: Color(0xFF00FF41),
      secondary: Color(0xFF00CC33),
      dim: Color(0xFF003B0F),
      text: Color(0xFF00FF41),
      textDim: Color(0xFF00AA2A),
      cursor: Color(0xFF00FF41),
    ),
    SpoonTheme.amber: _ThemeColors(
      background: Color(0xFF0D0A00),
      primary: Color(0xFFFFB000),
      secondary: Color(0xFFCC8C00),
      dim: Color(0xFF2B1D00),
      text: Color(0xFFFFB000),
      textDim: Color(0xFFAA7500),
      cursor: Color(0xFFFFB000),
    ),
    SpoonTheme.paperWhite: _ThemeColors(
      background: Color(0xFF0A0A0A),
      primary: Color(0xFFE8E8E8),
      secondary: Color(0xFFB0B0B0),
      dim: Color(0xFF1A1A1A),
      text: Color(0xFFE8E8E8),
      textDim: Color(0xFF888888),
      cursor: Color(0xFFE8E8E8),
    ),
    SpoonTheme.cyan: _ThemeColors(
      background: Color(0xFF000D0D),
      primary: Color(0xFF00FFFF),
      secondary: Color(0xFF00CCCC),
      dim: Color(0xFF003333),
      text: Color(0xFF00FFFF),
      textDim: Color(0xFF00AAAA),
      cursor: Color(0xFF00FFFF),
    ),
  };

  static ThemeData getTheme(SpoonTheme spoonTheme) {
    final colors = themes[spoonTheme]!;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.dim,
        onPrimary: colors.background,
        onSecondary: colors.background,
        onSurface: colors.text,
      ),
      textTheme: GoogleFonts.vt323TextTheme().apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.primary,
        elevation: 0,
        titleTextStyle: GoogleFonts.vt323(
          color: colors.primary,
          fontSize: 24,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: colors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colors.secondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
        hintStyle: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.dim,
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          textStyle: GoogleFonts.vt323(fontSize: 20, letterSpacing: 2),
        ),
      ),
      iconTheme: IconThemeData(color: colors.primary),
      dividerColor: colors.dim,
    );
  }

  static _ThemeColors getColors(SpoonTheme theme) => themes[theme]!;

  static String themeName(SpoonTheme theme) {
    switch (theme) {
      case SpoonTheme.phosphorGreen: return 'Phosphor Green';
      case SpoonTheme.amber: return 'Amber';
      case SpoonTheme.paperWhite: return 'Paper White';
      case SpoonTheme.cyan: return 'Cyan';
    }
  }
}

class _ThemeColors {
  final Color background;
  final Color primary;
  final Color secondary;
  final Color dim;
  final Color text;
  final Color textDim;
  final Color cursor;

  const _ThemeColors({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.dim,
    required this.text,
    required this.textDim,
    required this.cursor,
  });
}
