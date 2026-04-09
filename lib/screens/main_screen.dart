/// Главный экран — список кругов
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';
import '../transport/relay_client.dart';
import '../transport/messenger.dart';
import 'circle_screen.dart';
import 'settings_screen.dart';
import 'qr_screen.dart';

class MainScreen extends StatefulWidget {
  final SpoonTheme theme;
  final bool scanlines;
  final bool glow;
  final bool flicker;
  final Function(SpoonTheme) onThemeChanged;
  final Function(bool) onScanlinesChanged;
  final Function(bool) onGlowChanged;
  final Function(bool) onFlickerChanged;

  const MainScreen({
    super.key,
    required this.theme,
    required this.scanlines,
    required this.glow,
    required this.flicker,
    required this.onThemeChanged,
    required this.onScanlinesChanged,
    required this.onGlowChanged,
    required this.onFlickerChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Circle> _circles = [];
  NetworkStats? _stats;
  bool _statsLoading = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadCircles();
    _loadStats();
  }

  Future<void> _loadCircles() async {
    final circles = await CirclesStorage.getAll();
    setState(() => _circles = circles);
  }

  Future<void> _loadStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      final messenger = await SpoonMessenger.create();
      final stats = await messenger.getStats();
      if (mounted) setState(() { _stats = stats; _statsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _statsError = 'no live data'; _statsLoading = false; });
    }
  }

  Future<void> _createCircle() async {
    final colors = AppTheme.getColors(widget.theme);
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> CREATE BOARD',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.vt323(color: colors.text, fontSize: 20),
          decoration: InputDecoration(
            hintText: 'board name_',
            hintStyle: GoogleFonts.vt323(color: colors.textDim, fontSize: 20),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await CirclesStorage.create(nameController.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadCircles();
              }
            },
            child: GlowText(
              'CREATE',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinCircle() async {
    final colors = AppTheme.getColors(widget.theme);
    final keyController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> JOIN BOARD',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              style: GoogleFonts.vt323(color: colors.text, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'board key_',
                hintStyle: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: GoogleFonts.vt323(color: colors.text, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'board name_',
                hintStyle: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              if (keyController.text.isNotEmpty && nameController.text.isNotEmpty) {
                await CirclesStorage.join(keyController.text, nameController.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadCircles();
              }
            },
            child: GlowText(
              'JOIN',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_ooo.jpg',
              height: 24,
              width: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            GlowText(
              'NO SPOON APP',
              style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
              glowColor: colors.primary,
            ),
            const SizedBox(width: 8),
            BlinkingCursor(color: colors.cursor, fontSize: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  theme: widget.theme,
                  scanlines: widget.scanlines,
                  glow: widget.glow,
                  flicker: widget.flicker,
                  sound: false,
                  onThemeChanged: widget.onThemeChanged,
                  onScanlinesChanged: widget.onScanlinesChanged,
                  onGlowChanged: widget.onGlowChanged,
                  onFlickerChanged: widget.onFlickerChanged,
                  onSoundChanged: (_) {},
                ),
              ),
            ),
          ),
        ],
      ),
      body: CrtScreen(
        theme: widget.theme,
        scanlines: widget.scanlines,
        glow: widget.glow,
        flicker: widget.flicker,
        child: Column(
          children: [
            Expanded(
              child: _circles.isEmpty
                  ? _buildEmpty(colors)
                  : _buildCircleList(colors),
            ),
            _buildStatsBar(colors),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrScanScreen(theme: widget.theme),
              ),
            ).then((joined) {
              if (joined == true) _loadCircles();
            }),
            backgroundColor: colors.dim,
            child: Icon(Icons.qr_code_scanner, color: colors.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'join',
            onPressed: _joinCircle,
            backgroundColor: colors.dim,
            child: Icon(Icons.login, color: colors.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _createCircle,
            backgroundColor: colors.dim,
            child: Icon(Icons.add, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(dynamic colors) {
    final dimStyle = GoogleFonts.vt323(fontSize: 14, color: colors.textDim);
    final valStyle = GoogleFonts.vt323(fontSize: 16, color: colors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.secondary, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6,
            color: _statsError != null ? colors.textDim : colors.primary),
          const SizedBox(width: 6),
          if (_statsLoading)
            Text('relay...', style: dimStyle)
          else if (_statsError != null)
            Text('relay · $_statsError', style: dimStyle)
          else ...[
            Text('relay online', style: dimStyle),
            const Spacer(),
            Text('MSG ', style: dimStyle),
            Text('${_stats?.totalMessages ?? 0}', style: valStyle),
          ],
          if (_statsError != null || _statsLoading)
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmpty(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowText(
            'there is no spoon.',
            style: GoogleFonts.vt323(fontSize: 28, color: colors.primary),
            glowColor: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'no server.',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.textDim),
          ),
          Text(
            'no identity.',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.textDim),
          ),
          Text(
            'no trace.',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.textDim),
          ),
          const SizedBox(height: 16),
          GlowText(
            'only the message.',
            style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
            glowColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleList(dynamic colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _circles.length,
      itemBuilder: (ctx, i) {
        final circle = _circles[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.secondary),
            color: colors.dim,
          ),
          child: ListTile(
            title: GlowText(
              '> ${circle.name}',
              style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
              glowColor: colors.primary,
            ),
            subtitle: Text(
              'key: ${circle.key}',
              style: GoogleFonts.vt323(fontSize: 16, color: colors.textDim),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.primary),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CircleScreen(
                  circle: circle,
                  theme: widget.theme,
                  scanlines: widget.scanlines,
                  glow: widget.glow,
                  flicker: widget.flicker,
                ),
              ),
            ).then((_) => _loadCircles()),
          ),
        );
      },
    );
  }
}
