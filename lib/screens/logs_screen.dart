/// Экран логов для отладки

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../services/logger_service.dart';

class LogsScreen extends StatelessWidget {
  final SpoonTheme theme;

  const LogsScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> LOGS',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final text = logger.logs
                  .map((e) => e.formatted)
                  .join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'logs copied',
                    style: GoogleFonts.vt323(fontSize: 16),
                  ),
                  backgroundColor: colors.dim,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              logger.clear();
            },
          ),
        ],
      ),
      body: CrtScreen(
        theme: theme,
        scanlines: true,
        glow: false,
        child: ValueListenableBuilder<List<LogEntry>>(
          valueListenable: logger.logsNotifier,
          builder: (context, logs, _) {
            if (logs.isEmpty) {
              return Center(
                child: Text(
                  'no logs.',
                  style: GoogleFonts.vt323(
                    color: colors.textDim,
                    fontSize: 20,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              reverse: true,
              itemBuilder: (ctx, i) {
                final entry = logs[logs.length - 1 - i];
                Color entryColor;
                switch (entry.level) {
                  case 'ERROR':
                    entryColor = Colors.red;
                  case 'WARN':
                    entryColor = Colors.orange;
                  default:
                    entryColor = colors.textDim;
                }
                return Text(
                  entry.formatted,
                  style: GoogleFonts.vt323(
                    color: entryColor,
                    fontSize: 14,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
