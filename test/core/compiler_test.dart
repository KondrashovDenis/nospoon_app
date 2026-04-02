import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/compiler.dart';

void main() {
  group('BrainfuckCompiler', () {
    test('findBestFactor возвращает корректный множитель', () {
      for (final n in [65, 72, 101, 108, 111]) {
        final f = BrainfuckCompiler.findBestFactor(n);
        expect(f, greaterThanOrEqualTo(1));
        expect(f, lessThanOrEqualTo(n));
      }
    });

    test('compileChar возвращает непустую строку с точкой', () {
      for (final ascii in [65, 72, 101, 108, 111, 32]) {
        final result = BrainfuckCompiler.compileChar(ascii);
        expect(result, isNotEmpty);
        expect(result, contains('.'));
      }
    });

    test('compileText Hello содержит 5 точек', () {
      final result = BrainfuckCompiler.compileText('Hello');
      expect(result, isNotEmpty);
      expect('.'.allMatches(result).length, equals(5));
    });

    test('compileText пустая строка', () {
      expect(BrainfuckCompiler.compileText(''), isEmpty);
    });
  });
}
