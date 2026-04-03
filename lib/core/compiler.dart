/// Text → Brainfuck компилятор
/// Порт Python core/compiler.py на Dart

import 'dart:convert';

class BrainfuckCompiler {
  /// Найти лучший множитель для n
  static int findBestFactor(int n) {
    if (n == 0) return 1;
    int best = 1;
    int bestCost = n;
    for (int i = 2; i <= n; i++) {
      if (i * i > n * 2) break;
      final q = n ~/ i;
      final r = n % i;
      final cost = i + q + r + 6;
      if (cost < bestCost) {
        bestCost = cost;
        best = i;
      }
    }
    return best;
  }

  /// Скомпилировать один символ в BF код
  static String compileChar(int asciiVal) {
    if (asciiVal == 0) return '.';

    final factor = findBestFactor(asciiVal);
    final quotient = asciiVal ~/ factor;
    final remainder = asciiVal % factor;

    if (factor == 1) {
      return '+' * asciiVal + '.';
    }

    final bf = StringBuffer();
    bf.write('+' * factor);
    bf.write('[>+');
    bf.write('+' * (quotient - 1));
    bf.write('<-]');
    bf.write('>');
    bf.write('+' * remainder);
    bf.write('.');
    bf.write('[-]');
    bf.write('<');
    return bf.toString();
  }

  /// Скомпилировать строку текста в BF программу
  static String compileText(String text) {
    if (text.isEmpty) return '';
    final bytes = utf8.encode(text);
    final result = StringBuffer();
    for (final byte in bytes) {
      result.write(compileChar(byte));
    }
    return result.toString();
  }
}
