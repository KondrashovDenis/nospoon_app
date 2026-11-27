/// Цепочка кодирования: text → Brainfuck → TTL-обёртка → Spoon → .bin
///
/// Это кодирование, а не шифрование: .bin читается любым, кто знает Spoon.
/// Защиту даёт конверт поверх .bin — см. envelope.dart.
library;

import 'package:flutter/foundation.dart';
import 'compiler.dart';
import 'transcoder.dart';
import 'interpreter.dart';
import 'ttl.dart';

@immutable
class EncodeResult {
  final Uint8List binary;
  final String bfCode;
  final String bfWithTtl;
  final int sizeBytes;

  const EncodeResult({
    required this.binary,
    required this.bfCode,
    required this.bfWithTtl,
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
  /// Text → BF → TTL-обёртка → Spoon → .bin
  static EncodeResult encode(
    String text, {
    required DateTime createdAt,
    required int ttlSeconds,
  }) {
    if (text.isEmpty) throw ArgumentError('Текст не может быть пустым');
    if (ttlSeconds <= 0) throw ArgumentError('TTL должен быть положительным');

    final bfCode = BrainfuckCompiler.compileText(text);
    final bfWithTtl = wrapWithTtl(
      bfCode,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );
    final binary = SpoonTranscoder.encodeToBin(bfWithTtl);

    return EncodeResult(
      binary: binary,
      bfCode: bfCode,
      bfWithTtl: bfWithTtl,
      sizeBytes: binary.length,
    );
  }

  /// .bin → Spoon → BF → выполнить с токеном времени → Text
  ///
  /// [createdAt] и [ttlSeconds] берутся из заголовка конверта:
  /// по ним считается токен, который ждёт TTL-обёртка.
  static DecodeResult decode(
    Uint8List data, {
    required DateTime createdAt,
    required int ttlSeconds,
  }) {
    String bfCode = '';
    try {
      bfCode = SpoonTranscoder.decodeFromBin(data);
      final text = runBf(
        bfCode,
        stdin: stdinToken(createdAt, ttlSeconds),
      );

      if (text.isEmpty) {
        return DecodeResult(
          text: '',
          bfCode: bfCode,
          success: false,
          error: 'ttl_token_mismatch',
        );
      }

      return DecodeResult(text: text, bfCode: bfCode, success: true);
    } on BrainfuckError catch (e) {
      return DecodeResult(
        text: '',
        bfCode: bfCode,
        success: false,
        error: e.message,
      );
    } catch (e) {
      return DecodeResult(
        text: '',
        bfCode: bfCode,
        success: false,
        error: e.toString(),
      );
    }
  }
}
