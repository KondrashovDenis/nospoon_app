/// Экран настроек
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';

class SettingsScreen extends StatefulWidget {
  final SpoonTheme theme;

  const SettingsScreen({super.key, required this.theme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SpoonTheme _theme;
  bool _scanlines = true;
  bool _glow = true;
  bool _flicker = false;
  bool _sound = false;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO — загрузить из SharedPreferences через AppState
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> SETTINGS',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: CrtScreen(
        theme: _theme,
        scanlines: _scanlines,
        glow: _glow,
        flicker: _flicker,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Тема
            Text(
              '> THEME',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...SpoonTheme.values.map((t) {
              final selected = _theme == t;
              return GestureDetector(
                onTap: () => setState(() => _theme = t),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? colors.primary : colors.secondary,
                    ),
                    color: selected ? colors.dim : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      if (selected)
                        GlowText(
                          '> ',
                          style: GoogleFonts.vt323(
                            fontSize: 20, color: colors.primary,
                          ),
                          glowColor: colors.primary,
                        ),
                      Text(
                        AppTheme.themeName(t),
                        style: GoogleFonts.vt323(
                          color: selected ? colors.primary : colors.textDim,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            Text(
              '> EFFECTS',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 8),

            _buildToggle('SCANLINES', _scanlines, colors,
                (v) => setState(() => _scanlines = v)),
            _buildToggle('PHOSPHOR GLOW', _glow, colors,
                (v) => setState(() => _glow = v)),
            _buildToggle('SCREEN FLICKER', _flicker, colors,
                (v) => setState(() => _flicker = v)),
            _buildToggle('SOUND', _sound, colors,
                (v) => setState(() => _sound = v)),

            const SizedBox(height: 24),
            Text(
              '> ABOUT',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'spoon messenger v1.3.0\nthere is no server.\nthere is no spoon.',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    dynamic colors,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colors.secondary),
        color: colors.dim,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.vt323(color: colors.text, fontSize: 20),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
            inactiveTrackColor: colors.background,
          ),
        ],
      ),
    );
  }
}
