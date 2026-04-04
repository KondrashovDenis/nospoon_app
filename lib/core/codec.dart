/// Единый интерфейс цепочки кодирования
/// Порт Python core/codec.py на Dart
library;

import 'dart:typed_data';
import 'compiler.dart';
import 'transcoder.dart';
import 'interpreter.dart';
import 'ttl.dart';

/// Маркер сообщения с паролем.
/// Если декодированный текст начинается с этого маркера —
/// значит сообщение защищено паролем.
const String passwordMarker = '\u{1F512}'; // 🔒

class EncodeResult {
  final Uint8List binary;
  final String bfCode;
  final String bfWithTtl;
  final DateTime expiresAt;
  final int sizeBytes;

  EncodeResult({
    required this.binary,
    required this.bfCode,
    required this.bfWithTtl,
    required this.expiresAt,
    required this.sizeBytes,
  });
}

class DecodeResult {
  final String text;
  final String bfCode;
  final bool success;
  final String? error;

  DecodeResult({
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

    // Добавить маркер если есть пароль
    final actualText = password != null && password.isNotEmpty
        ? passwordMarker + text
        : text;

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

      String resultText = '';

      for (final token in tokens) {
        try {
          final text = runBf(bfCode, stdin: token);
          if (text.isNotEmpty) {
            if (text.startsWith(passwordMarker)) {
              // Сообщение с паролем
              if (password != null && password.isNotEmpty) {
                for (final t in tokens) {
                  try {
                    final textWithPass = runBf(bfCode, stdin: t + password);
                    if (textWithPass.isNotEmpty &&
                        textWithPass.startsWith(passwordMarker)) {
                      resultText =
                          textWithPass.substring(passwordMarker.length);
                      break;
                    }
                  } catch (_) {}
                }
              }
              if (resultText.isEmpty) {
                // Сигнал: нужен пароль
                resultText = passwordMarker;
              }
            } else {
              resultText = text;
            }
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (resultText.isEmpty) {
        return DecodeResult(
          text: '',
          bfCode: bfCode,
          success: false,
          error: 'TTL истёк',
        );
      }

      if (resultText == passwordMarker) {
        return DecodeResult(
          text: passwordMarker,
          bfCode: bfCode,
          success: false,
          error: 'password_required',
        );
      }

      return DecodeResult(
        text: resultText,
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
