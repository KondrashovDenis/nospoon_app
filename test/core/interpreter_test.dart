import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/interpreter.dart';

void main() {
  group('BrainfuckInterpreter', () {
    test('Hello World', () {
      const bf = '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.';
      expect(runBf(bf), equals('Hello World!\n'));
    });

    test('stdin input', () {
      expect(runBf(',.', stdin: 'X'), equals('X'));
    });

    test('бесконечный цикл — исключение', () {
      expect(
        () => runBf('+[]', maxSteps: 1000),
        throwsA(isA<BrainfuckError>()),
      );
    });

    test('пустая программа', () {
      expect(runBf(''), isEmpty);
    });
  });
}
