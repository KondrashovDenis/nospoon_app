/// Экран настроек
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../screens/logs_screen.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  final SpoonTheme theme;
  final bool scanlines;
  final bool glow;
  final bool flicker;
  final bool sound;
  final Function(SpoonTheme) onThemeChanged;
  final Function(bool) onScanlinesChanged;
  final Function(bool) onGlowChanged;
  final Function(bool) onFlickerChanged;
  final Function(bool) onSoundChanged;

  const SettingsScreen({
    super.key,
    required this.theme,
    required this.scanlines,
    required this.glow,
    required this.flicker,
    required this.sound,
    required this.onThemeChanged,
    required this.onScanlinesChanged,
    required this.onGlowChanged,
    required this.onFlickerChanged,
    required this.onSoundChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SpoonTheme _theme;
  late bool _scanlines;
  late bool _glow;
  late bool _flicker;
  late bool _sound;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
    _scanlines = widget.scanlines;
    _glow = widget.glow;
    _flicker = widget.flicker;
    _sound = widget.sound;
    _loadSound();
  }

  Future<void> _loadSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sound = prefs.getBool('sound') ?? false;
    });
  }

  Future<void> _saveTheme(SpoonTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    widget.onThemeChanged(theme);
  }

  Future<void> _saveScanlines(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scanlines', value);
    widget.onScanlinesChanged(value);
  }

  Future<void> _saveGlow(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glow', value);
    widget.onGlowChanged(value);
  }

  Future<void> _saveFlicker(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flicker', value);
    widget.onFlickerChanged(value);
  }

  Future<void> _saveSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', value);
    SoundService().setEnabled(value);
    widget.onSoundChanged(value);
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
            Text(
              '> THEME',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...SpoonTheme.values.map((t) {
              final selected = _theme == t;
              final tColors = AppTheme.getColors(t);
              return GestureDetector(
                onTap: () {
                  setState(() => _theme = t);
                  _saveTheme(t);
                },
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
                      Container(
                        width: 16,
                        height: 16,
                        color: tColors.primary,
                        margin: const EdgeInsets.only(right: 12),
                      ),
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

            _buildToggle('SCANLINES', _scanlines, colors, (v) {
              setState(() => _scanlines = v);
              _saveScanlines(v);
            }),
            _buildToggle('PHOSPHOR GLOW', _glow, colors, (v) {
              setState(() => _glow = v);
              _saveGlow(v);
            }),
            _buildToggle('SCREEN FLICKER', _flicker, colors, (v) {
              setState(() => _flicker = v);
              _saveFlicker(v);
            }),
            _buildToggle('SOUND', _sound, colors, (v) {
              setState(() => _sound = v);
              _saveSound(v);
            }),

            const SizedBox(height: 24),
            Text(
              '> ABOUT',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'no spoon messenger v2.0.0',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 16),
            GlowText(
              'there is no spoon.',
              style: GoogleFonts.vt323(fontSize: 20, color: colors.primary),
              glowColor: colors.primary,
            ),
            Text(
              'no server.\nno identity.\nno trace.\n\nonly the message.',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogsScreen(theme: _theme),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.secondary),
                  color: colors.dim,
                ),
                child: Text(
                  '> VIEW LOGS',
                  style: GoogleFonts.vt323(color: colors.textDim, fontSize: 20),
                ),
              ),
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
