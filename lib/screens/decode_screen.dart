/// Экран декодирования — заглушка для v1.4.0
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';

class DecodeScreen extends StatelessWidget {
  final SpoonTheme theme;

  const DecodeScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> DECODE',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: CrtScreen(
        theme: theme,
        scanlines: true,
        glow: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowText(
                'CEREMONY',
                style: GoogleFonts.vt323(fontSize: 40, color: colors.primary),
                glowColor: colors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'v1.4.0 — coming soon',
                style: GoogleFonts.vt323(fontSize: 20, color: colors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
