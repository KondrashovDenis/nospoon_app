/// Глобальное состояние приложения
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  SpoonTheme _theme = SpoonTheme.phosphorGreen;
  bool _scanlines = true;
  bool _glow = true;
  bool _flicker = false;
  bool _sound = false;
  bool _initialized = false;

  SpoonTheme get theme => _theme;
  bool get scanlines => _scanlines;
  bool get glow => _glow;
  bool get flicker => _flicker;
  bool get sound => _sound;
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _theme = SpoonTheme.values[prefs.getInt('theme') ?? 0];
    _scanlines = prefs.getBool('scanlines') ?? true;
    _glow = prefs.getBool('glow') ?? true;
    _flicker = prefs.getBool('flicker') ?? false;
    _sound = prefs.getBool('sound') ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setTheme(SpoonTheme theme) async {
    _theme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    notifyListeners();
  }

  Future<void> setScanlines(bool value) async {
    _scanlines = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scanlines', value);
    notifyListeners();
  }

  Future<void> setGlow(bool value) async {
    _glow = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glow', value);
    notifyListeners();
  }

  Future<void> setFlicker(bool value) async {
    _flicker = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flicker', value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', value);
    notifyListeners();
  }
}
