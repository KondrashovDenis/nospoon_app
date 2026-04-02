/// Экран круга — лента посланий
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';
import 'compose_screen.dart';

class CircleScreen extends StatelessWidget {
  final Circle circle;
  final SpoonTheme theme;
  final bool scanlines;
  final bool glow;
  final bool flicker;

  const CircleScreen({
    super.key,
    required this.circle,
    required this.theme,
    required this.scanlines,
    required this.glow,
    required this.flicker,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> ${circle.name}',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCircleInfo(context, colors),
          ),
        ],
      ),
      body: CrtScreen(
        theme: theme,
        scanlines: scanlines,
        glow: glow,
        flicker: flicker,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowText(
                'CIRCLE FEED',
                style: GoogleFonts.vt323(fontSize: 28, color: colors.primary),
                glowColor: colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'v1.4.0 — coming soon',
                style: GoogleFonts.vt323(fontSize: 18, color: colors.textDim),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComposeScreen(
              circle: circle,
              theme: theme,
            ),
          ),
        ),
        backgroundColor: colors.dim,
        child: Icon(Icons.edit, color: colors.primary),
      ),
    );
  }

  void _showCircleInfo(BuildContext context, dynamic colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> CIRCLE INFO',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('name: ${circle.name}',
                style: GoogleFonts.vt323(color: colors.text, fontSize: 18)),
            const SizedBox(height: 8),
            Text('key:', style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16)),
            SelectableText(
              circle.key,
              style: GoogleFonts.vt323(color: colors.primary, fontSize: 20),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: GlowText(
              'CLOSE',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
