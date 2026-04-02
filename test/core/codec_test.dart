import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/codec.dart';

void main() {
  group('SpoonCodec', () {
    test('encode возвращает EncodeResult', () {
      final result = SpoonCodec.encode('Hello', ttlSeconds: 3600);
      expect(result.binary, isNotEmpty);
      expect(result.bfCode, isNotEmpty);
      expect(result.sizeBytes, equals(result.binary.length));
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('decode roundtrip', () {
      const text = 'Hello';
      final encoded = SpoonCodec.encode(text, ttlSeconds: 3600);
      final decoded = SpoonCodec.decode(encoded.binary);
      expect(decoded.success, isTrue);
      expect(decoded.text, equals(text));
    });

    test('decode разные тексты', () {
      for (final text in ['Hi', 'Hello', 'A', 'Test 123']) {
        final encoded = SpoonCodec.encode(text, ttlSeconds: 3600);
        final decoded = SpoonCodec.decode(encoded.binary);
        expect(decoded.success, isTrue, reason: 'Failed for $text');
        expect(decoded.text, equals(text));
      }
    });

    test('encode пустой текст — исключение', () {
      expect(() => SpoonCodec.encode(''), throwsArgumentError);
    });

    test('decode неверный токен — failure', () {
      final encoded = SpoonCodec.encode('Hello', ttlSeconds: 3600);
      final pastTime = DateTime.now().subtract(const Duration(days: 30));
      final decoded = SpoonCodec.decode(encoded.binary, timestamp: pastTime);
      expect(decoded.success, isFalse);
    });
  });
}
