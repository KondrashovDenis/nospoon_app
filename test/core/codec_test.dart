import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/codec.dart';
import 'package:nospoon_app/core/compiler.dart';
import 'package:nospoon_app/core/interpreter.dart';

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

    test('passwordMarker компилируется и декодируется корректно', () {
      final bf = BrainfuckCompiler.compileText('\x01Secret');
      final result = runBf(bf);
      expect(result, equals('\x01Secret'));
    });

    test('encode без пароля декодируется напрямую', () {
      const text = 'Hello';
      final encoded = SpoonCodec.encode(text, ttlSeconds: 3600);
      final decoded = SpoonCodec.decode(encoded.binary);
      expect(decoded.success, isTrue);
      expect(decoded.text, equals(text));
    });

    test('encode с паролем — без пароля возвращает password_required', () {
      final encoded = SpoonCodec.encode('Secret', ttlSeconds: 3600, password: 'key123');
      final decoded = SpoonCodec.decode(encoded.binary);
      expect(decoded.success, isFalse);
      expect(decoded.error, equals('password_required'));
    });

    test('encode с паролем — верный пароль декодирует текст', () {
      const text = 'Secret message';
      const password = 'mykey';
      final encoded = SpoonCodec.encode(text, ttlSeconds: 3600, password: password);
      final decoded = SpoonCodec.decode(encoded.binary, password: password);
      expect(decoded.success, isTrue);
      expect(decoded.text, equals(text));
    });

    test('encode с паролем — неверный пароль возвращает wrong_password', () {
      final encoded = SpoonCodec.encode('Secret', ttlSeconds: 3600, password: 'correct');
      final decoded = SpoonCodec.decode(encoded.binary, password: 'wrong');
      expect(decoded.success, isFalse);
      expect(decoded.error, equals('wrong_password'));
    });

    test('encode с паролем — кириллица', () {
      const text = 'Привет мир';
      const password = 'пароль';
      final encoded = SpoonCodec.encode(text, ttlSeconds: 3600, password: password);
      final decoded = SpoonCodec.decode(encoded.binary, password: password);
      expect(decoded.success, isTrue);
      expect(decoded.text, equals(text));
    });
  });
}
