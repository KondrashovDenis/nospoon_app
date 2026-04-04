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

    test('encode с паролем добавляет маркер', () {
      final result = SpoonCodec.encode('Secret', ttlSeconds: 3600, password: 'key');
      // Декодирование без пароля должно вернуть password_required
      final decoded = SpoonCodec.decode(result.binary);
      expect(decoded.error, equals('password_required'));
    });

    test('encode с паролем декодируется с правильным паролем', () {
      const text = 'Secret';
      const password = 'mykey';
      final encoded = SpoonCodec.encode(text, ttlSeconds: 3600, password: password);
      final decoded = SpoonCodec.decode(encoded.binary, password: password);
      expect(decoded.success, isTrue);
      expect(decoded.text, equals(text));
    });
  });
}
