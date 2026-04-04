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

    final bf = StringBuffer();

    if (factor == 1 || quotient == 0) {
      // Наивный вариант для малых значений
      bf.write('+' * asciiVal);
      bf.write('.');
      bf.write('[-]'); // очистить ячейку
      return bf.toString();
    }

    // Структура: используем две ячейки
    // cell[ptr] = счётчик цикла (factor)
    // cell[ptr+1] = рабочая ячейка (накапливаем quotient * factor)
    bf.write('+' * factor);          // cell0 = factor
    bf.write('[');                    // начало цикла
    bf.write('>');                    // перейти в cell1
    bf.write('+' * quotient);        // добавить quotient
    bf.write('<');                    // вернуться в cell0
    bf.write('-');                    // декрементировать счётчик
    bf.write(']');                    // конец цикла
    bf.write('>');                    // перейти в cell1 (= factor * quotient)
    bf.write('+' * remainder);       // добавить остаток
    bf.write('.');                    // вывести символ
    bf.write('[-]');                  // очистить cell1
    bf.write('<');                    // вернуться в cell0 (уже 0)

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
