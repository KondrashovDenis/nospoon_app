/// Единый интерфейс цепочки кодирования
/// Порт Python core/codec.py на Dart

import 'dart:typed_data';
import 'compiler.dart';
import 'transcoder.dart';
import 'interpreter.dart';
import 'ttl.dart';

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

    // Шаг 1: Text → BF
    final bfCode = BrainfuckCompiler.compileText(text);

    // Шаг 2: BF + TTL
    final (bfWithTtl, expiresAt) = wrapSimple(bfCode, ttlSeconds: ttlSeconds);

    // Шаг 3: BF → .bin
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
      // Шаг 1: .bin → BF
      final bfCode = SpoonTranscoder.decodeFromBin(data);

      // Шаг 2: stdin = временной токен
      String stdin = getStdinToken(timestamp: timestamp);
      if (password != null) stdin += password;

      // Шаг 3: выполнить BF
      final text = runBf(bfCode, stdin: stdin);

      if (text.isEmpty) {
        return DecodeResult(
          text: '',
          bfCode: bfCode,
          success: false,
          error: 'TTL истёк или неверный пароль',
        );
      }

      return DecodeResult(
        text: text,
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
