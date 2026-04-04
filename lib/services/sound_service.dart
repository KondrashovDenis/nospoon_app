/// Звуковой сервис через flutter_soloud
/// Кроссплатформенный: Android, iOS, Windows, macOS
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = false;
  bool _initialized = false;
  int _plusCount = 0;
  int _minusCount = 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sound') ?? false;

    if (!_initialized) {
      try {
        await SoLoud.instance.init();
        _initialized = true;
      } catch (e) {
        debugPrint('SoLoud init error: $e');
      }
    }
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  bool get enabled => _enabled;

  /// Генерировать и играть тон через SoLoud
  Future<void> _playTone({
    required double frequency,
    required int durationMs,
    required double volume,
    WaveForm waveForm = WaveForm.sin,
  }) async {
    if (!_enabled || !_initialized) return;
    try {
      final source = await SoLoud.instance.loadWaveform(
        waveForm,
        true,
        0.25,
        1,
      );
      final handle = await SoLoud.instance.play(
        source,
        volume: volume,
      );
      SoLoud.instance.setRelativePlaySpeed(handle, frequency / 440.0);
      await Future.delayed(Duration(milliseconds: durationMs));
      SoLoud.instance.stop(handle);
      SoLoud.instance.disposeSource(source);
    } catch (e) {
      debugPrint('SoLoud play error: $e');
    }
  }

  bool _modemLooping = false;

  /// Запустить петлю модема пока идёт загрузка
  Future<void> startModemLoop() async {
    if (!_enabled || !_initialized) return;
    _modemLooping = true;
    _runModemLoop();
  }

  /// Остановить петлю модема
  void stopModemLoop() {
    _modemLooping = false;
  }

  Future<void> _runModemLoop() async {
    final sequence = [
      (1200.0, 90,  0),
      (2400.0, 60,  90),
      (1800.0, 110, 0),
      (600.0,  45,  180),
      (2200.0, 80,  0),
      (900.0,  70,  70),
      (1500.0, 55,  0),
      (2100.0, 95,  110),
      (1100.0, 40,  0),
      (1900.0, 85,  0),
      (750.0,  65,  160),
      (2600.0, 50,  0),
      (1350.0, 75,  75),
      (500.0,  100, 0),
      (2050.0, 45,  0),
      (1650.0, 80,  0),
      (2300.0, 55,  0),
      (850.0,  70,  85),
      (1750.0, 60,  0),
      (2700.0, 40,  0),
      (1050.0, 90,  0),
      (1450.0, 50,  0),
      (2150.0, 75,  100),
      (650.0,  85,  0),
      (1950.0, 45,  0),
      (2450.0, 65,  0),
      (1250.0, 80,  0),
      (550.0,  55,  0),
      (2350.0, 70,  90),
      (1550.0, 60,  0),
      (800.0,  95,  0),
      (2000.0, 50,  0),
    ];

    int i = 0;
    while (_modemLooping && _initialized) {
      if (!_enabled) break;
      final (freq, dur, pause) = sequence[i % sequence.length];
      try {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.sin, true, 0.25, 1,
        );
        final handle = await SoLoud.instance.play(source, volume: 0.2);
        SoLoud.instance.setRelativePlaySpeed(handle, freq / 440.0);
        await Future.delayed(Duration(milliseconds: dur));
        SoLoud.instance.stop(handle);
        SoLoud.instance.disposeSource(source);

        if (pause > 0 && _modemLooping) {
          await Future.delayed(Duration(milliseconds: pause));
        }
      } catch (_) {}
      i++;
    }
  }

  /// Одиночный модем (без петли) — для обратной совместимости
  Future<void> playModem() async {
    if (!_enabled || !_initialized) return;
    try {
      for (final freq in [1200.0, 2200.0, 1200.0]) {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.sin, true, 0.25, 1,
        );
        final handle = await SoLoud.instance.play(source, volume: 0.3);
        SoLoud.instance.setRelativePlaySpeed(handle, freq / 440.0);
        await Future.delayed(const Duration(milliseconds: 120));
        SoLoud.instance.stop(handle);
        SoLoud.instance.disposeSource(source);
      }
    } catch (e) {
      debugPrint('playModem error: $e');
    }
  }

  /// Щелчок завершения загрузки
  Future<void> playClick() async {
    await _playTone(
      frequency: 800,
      durationMs: 40,
      volume: 0.4,
      waveForm: WaveForm.square,
    );
  }

  /// Бит 0 — низкий тон
  Future<void> playBitZero() async {
    await _playTone(
      frequency: 440,
      durationMs: 20,
      volume: 0.15,
    );
  }

  /// Бит 1 — высокий тон
  Future<void> playBitOne() async {
    await _playTone(
      frequency: 880,
      durationMs: 20,
      volume: 0.15,
    );
  }

  void resetPlusCount() => _plusCount = 0;
  void resetMinusCount() => _minusCount = 0;

  /// + с нарастающей частотой
  Future<void> playPlus() async {
    _plusCount++;
    _minusCount = 0;
    final freq = (300 + _plusCount * 20.0).clamp(300.0, 1100.0);
    final vol = (0.1 + _plusCount * 0.015).clamp(0.1, 0.35);
    await _playTone(
      frequency: freq,
      durationMs: 15,
      volume: vol,
      waveForm: WaveForm.sin,
    );
  }

  /// - с убывающей частотой
  Future<void> playMinus() async {
    _minusCount++;
    _plusCount = 0;
    final freq = (1100 - _minusCount * 20.0).clamp(300.0, 1100.0);
    final vol = (0.1 + _minusCount * 0.015).clamp(0.1, 0.35);
    await _playTone(
      frequency: freq,
      durationMs: 15,
      volume: vol,
      waveForm: WaveForm.sin,
    );
  }

  Future<void> playRight() async {
    _plusCount = 0; _minusCount = 0;
    await _playTone(frequency: 1200, durationMs: 12, volume: 0.12,
        waveForm: WaveForm.square);
  }

  Future<void> playLeft() async {
    _plusCount = 0; _minusCount = 0;
    await _playTone(frequency: 600, durationMs: 12, volume: 0.12,
        waveForm: WaveForm.square);
  }

  Future<void> playLoopOpen() async {
    _plusCount = 0; _minusCount = 0;
    await _playTone(frequency: 200, durationMs: 40, volume: 0.2,
        waveForm: WaveForm.sin);
  }

  Future<void> playLoopClose() async {
    _plusCount = 0; _minusCount = 0;
    await _playTone(frequency: 400, durationMs: 40, volume: 0.2,
        waveForm: WaveForm.sin);
  }

  Future<void> playOutput() async {
    _plusCount = 0; _minusCount = 0;
    await _playTone(frequency: 1760, durationMs: 50, volume: 0.3,
        waveForm: WaveForm.sin);
  }

  /// Финальный сигнал успеха — C5 → E5 → G5
  Future<void> playSuccess() async {
    if (!_enabled || !_initialized) return;
    final notes = [523.25, 659.25, 783.99];
    for (final note in notes) {
      await _playTone(
        frequency: note,
        durationMs: 180,
        volume: 0.4,
        waveForm: WaveForm.sin,
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Тон для символа текста — уникальная мелодия
  Future<void> playCharacter(int charCode) async {
    final freq = 220.0 + (charCode % 12) * 55.0;
    await _playTone(
      frequency: freq,
      durationMs: 70,
      volume: 0.25,
      waveForm: WaveForm.sin,
    );
  }

  void dispose() {
    if (_initialized) {
      SoLoud.instance.deinit();
    }
  }
}
