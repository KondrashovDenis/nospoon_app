import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/codec.dart';
import 'package:nospoon_app/core/interpreter.dart';
import 'package:nospoon_app/core/transcoder.dart';
import 'package:nospoon_app/core/ttl.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 27, 12, 0, 0);
  const ttl = 3600;

  group('SpoonCodec', () {
    test('encode возвращает .bin и BF', () {
      final result = SpoonCodec.encode('Hello', createdAt: createdAt, ttlSeconds: ttl);
      expect(result.binary, isNotEmpty);
      expect(result.bfCode, isNotEmpty);
      expect(result.bfWithTtl, contains(result.bfCode));
      expect(result.sizeBytes, equals(result.binary.length));
    });

    test('roundtrip для разных текстов', () {
      for (final text in ['A', 'Hi', 'Hello', 'Test 123', 'line1\nline2', 'Привет, мир', '🥄 no spoon']) {
        final encoded = SpoonCodec.encode(text, createdAt: createdAt, ttlSeconds: ttl);
        final decoded = SpoonCodec.decode(encoded.binary, createdAt: createdAt, ttlSeconds: ttl);
        expect(decoded.success, isTrue, reason: 'Failed for $text');
        expect(decoded.text, equals(text));
      }
    });

    test('roundtrip для всех TTL из интерфейса', () {
      for (final seconds in [3600, 21600, 86400, 604800]) {
        final encoded = SpoonCodec.encode('ttl $seconds', createdAt: createdAt, ttlSeconds: seconds);
        final decoded = SpoonCodec.decode(encoded.binary, createdAt: createdAt, ttlSeconds: seconds);
        expect(decoded.success, isTrue, reason: 'ttl=$seconds');
        expect(decoded.text, equals('ttl $seconds'));
      }
    });

    test('максимальное сообщение (350 символов кириллицы) укладывается в лимит шагов', () {
      final text = 'Ж' * 350;
      final encoded = SpoonCodec.encode(text, createdAt: createdAt, ttlSeconds: ttl);
      final decoded = SpoonCodec.decode(encoded.binary, createdAt: createdAt, ttlSeconds: ttl);
      expect(decoded.success, isTrue, reason: decoded.error);
      expect(decoded.text, equals(text));
      expect(encoded.sizeBytes, lessThan(48 * 1024), reason: 'должно влезать в лимит relay');
    });

    test('пустой текст — исключение', () {
      expect(
        () => SpoonCodec.encode('', createdAt: createdAt, ttlSeconds: ttl),
        throwsArgumentError,
      );
    });

    test('чужой заголовок (другое время создания) — программа молчит', () {
      final encoded = SpoonCodec.encode('Hello', createdAt: createdAt, ttlSeconds: ttl);
      final decoded = SpoonCodec.decode(
        encoded.binary,
        createdAt: createdAt.add(const Duration(hours: 5)),
        ttlSeconds: ttl,
      );
      expect(decoded.success, isFalse);
      expect(decoded.error, equals('ttl_token_mismatch'));
    });

    test('мусор вместо .bin — failure без исключения', () {
      final garbage = SpoonTranscoder.bitsToBytes('0111' * 10); // одни «]»
      final decoded = SpoonCodec.decode(garbage, createdAt: createdAt, ttlSeconds: ttl);
      expect(decoded.success, isFalse);
    });
  });

  group('TTL-обёртка', () {
    test('токен детерминирован и меняется с периодом', () {
      expect(timeToken(createdAt, ttl), equals(timeToken(createdAt, ttl)));
      expect(
        timeToken(createdAt, ttl),
        isNot(equals(timeToken(createdAt.add(const Duration(seconds: ttl)), ttl))),
      );
      expect(timeToken(createdAt, ttl), inInclusiveRange(0, 255));
    });

    test('тело выполняется только с верным токеном', () {
      const body = '++++++++[>++++++++<-]>+.[-]<'; // печатает 'A'
      final wrapped = wrapWithTtl(body, createdAt: createdAt, ttlSeconds: ttl);
      final token = timeToken(createdAt, ttl);

      expect(runBf(wrapped, stdin: String.fromCharCode(token)), equals('A'));
      expect(runBf(wrapped, stdin: String.fromCharCode((token + 1) % 256)), isEmpty);
      expect(runBf(wrapped), token == 0 ? equals('A') : isEmpty);
    });

    test('токен 0 и 255 — граничные значения работают', () {
      const body = '++++++++[>++++++++<-]>+.[-]<';
      // 0 секунд эпохи → токен 0; 255 периодов → токен 255
      final zero = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final last = DateTime.fromMillisecondsSinceEpoch(255 * ttl * 1000, isUtc: true);
      expect(timeToken(zero, ttl), equals(0));
      expect(timeToken(last, ttl), equals(255));
      for (final t in [zero, last]) {
        final wrapped = wrapWithTtl(body, createdAt: t, ttlSeconds: ttl);
        expect(runBf(wrapped, stdin: stdinToken(t, ttl)), equals('A'));
      }
    });
  });
}
