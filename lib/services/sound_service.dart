/// Звуковые эффекты Spoon Messenger

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sound') ?? false;
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Звук модема при загрузке feed
  Future<void> playModem() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/modem.mp3'));
    } catch (_) {}
  }

  /// Звук печатной машинки при выводе символа
  Future<void> playTypewriter() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/typewriter.mp3'));
    } catch (_) {}
  }

  /// Стоп
  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
