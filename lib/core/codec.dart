/// Единый интерфейс цепочки кодирования
/// Порт Python core/codec.py на Dart
library;

import 'package:flutter/foundation.dart';
import 'compiler.dart';
import 'transcoder.dart';
import 'interpreter.dart';
import 'ttl.dart';

/// Маркер защищённого сообщения — однобайтный SOH символ
/// Никогда не встречается в реальном тексте пользователя
const String passwordMarker = '\x01';

/// Хэш пароля для проверки — простой но надёжный
/// Возвращает число от 0 до 255
int _passwordHash(String password) {
  int hash = 7;
  for (final char in password.codeUnits) {
    hash = (hash * 31 + char) & 0xFF;
  }
  return hash;
}

@immutable
class EncodeResult {
  final Uint8List binary;
  final String bfCode;
  final String bfWithTtl;
  final DateTime expiresAt;
  final int sizeBytes;

  const EncodeResult({
    required this.binary,
    required this.bfCode,
    required this.bfWithTtl,
    required this.expiresAt,
    required this.sizeBytes,
  });
}

@immutable
class DecodeResult {
  final String text;
  final String bfCode;
  final bool success;
  final String? error;

  const DecodeResult({
    required this.text,
    required this.bfCode,
    required this.success,
    this.error,
  });
}

class SpoonCodec {
  /// Text → BF → TTL → Spoon → .bin
  static EncodeResult encode(
    String text, {
    int ttlSeconds = 86400,
    String? password,
  }) {
    if (text.isEmpty) throw ArgumentError('Текст не может быть пустым');

    String actualText;
    if (password != null && password.isNotEmpty) {
      // Структура защищённого сообщения:
      // \x01 + chr(hash) + text
      // \x01 — маркер что сообщение защищено
      // chr(hash) — хэш пароля для проверки
      final hash = _passwordHash(password);
      actualText = passwordMarker + String.fromCharCode(hash) + text;
    } else {
      actualText = text;
    }

    final bfCode = BrainfuckCompiler.compileText(actualText);
    final (bfWithTtl, expiresAt) = wrapSimple(bfCode, ttlSeconds: ttlSeconds);
    final binary = SpoonTranscoder.encodeToBin(bfWithTtl);

    return EncodeResult(
      binary: binary,
      bfCode: bfCode,
      bfWithTtl: bfWithTtl,
      expiresAt: expiresAt,
      sizeBytes: binary.length,
    );
  }

  /// .bin → Spoon → BF → выполнить → Text
  static DecodeResult decode(
    Uint8List data, {
    String? password,
    DateTime? timestamp,
  }) {
    try {
      final bfCode = SpoonTranscoder.decodeFromBin(data);
      final tokens = getAllValidTokens(timestamp: timestamp);

      String rawText = '';

      for (final token in tokens) {
        try {
          final text = runBf(bfCode, stdin: token);
          if (text.isNotEmpty) {
            rawText = text;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (rawText.isEmpty) {
        return const DecodeResult(
          text: '',
          bfCode: '',
          success: false,
          error: 'TTL истёк',
        );
      }

      // Проверить структуру сообщения
      if (rawText.startsWith(passwordMarker)) {
        // Сообщение защищено паролем
        if (rawText.length < 2) {
          // Некорректная структура
          return DecodeResult(
            text: '',
            bfCode: bfCode,
            success: false,
            error: 'password_required',
          );
        }

        if (password == null || password.isEmpty) {
          // Пароль не передан
          return DecodeResult(
            text: '',
            bfCode: bfCode,
            success: false,
            error: 'password_required',
          );
        }

        // Проверить хэш пароля
        final storedHash = rawText.codeUnitAt(1);
        final providedHash = _passwordHash(password);

        if (storedHash != providedHash) {
          // Неверный пароль
          return DecodeResult(
            text: '',
            bfCode: bfCode,
            success: false,
            error: 'wrong_password',
          );
        }

        // Верный пароль — вернуть текст без маркера и хэша
        return DecodeResult(
          text: rawText.substring(2),
          bfCode: bfCode,
          success: true,
        );
      }

      // Обычное сообщение без пароля
      return DecodeResult(
        text: rawText,
        bfCode: bfCode,
        success: true,
      );
    } on BrainfuckError catch (e) {
      return DecodeResult(
        text: '',
        bfCode: '',
        success: false,
        error: e.message,
      );
    } catch (e) {
      return DecodeResult(
        text: '',
        bfCode: '',
        success: false,
        error: e.toString(),
      );
    }
  }
}
