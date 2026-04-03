/// Brainfuck интерпретатор
/// Порт Python core/interpreter.py на Dart
library;

import 'dart:convert';

class BrainfuckError implements Exception {
  final String message;
  BrainfuckError(this.message);
  @override
  String toString() => 'BrainfuckError: $message';
}

class BrainfuckInterpreter {
  final int tapeSize;
  final int maxSteps;

  BrainfuckInterpreter({
    this.tapeSize = 30000,
    this.maxSteps = 1000000,
  });

  String run(String bfCode, {String stdin = ''}) {
    final tape = List<int>.filled(tapeSize, 0);
    int ptr = 0;
    int pc = 0;
    final outputBytes = <int>[];
    int inputPtr = 0;
    int steps = 0;

    final bracketMap = _buildBracketMap(bfCode);

    // stdin как байты для корректной работы с UTF-8 токенами
    final stdinBytes = utf8.encode(stdin);

    while (pc < bfCode.length) {
      final cmd = bfCode[pc];
      steps++;

      if (steps > maxSteps) {
        throw BrainfuckError(
          'Превышен лимит шагов ($maxSteps). TTL истёк или бесконечный цикл.'
        );
      }

      switch (cmd) {
        case '+':
          tape[ptr] = (tape[ptr] + 1) % 256;
        case '-':
          tape[ptr] = (tape[ptr] - 1 + 256) % 256;
        case '>':
          ptr++;
          if (ptr >= tapeSize) {
            throw BrainfuckError('Выход за пределы ленты (вправо)');
          }
        case '<':
          ptr--;
          if (ptr < 0) {
            throw BrainfuckError('Выход за пределы ленты (влево)');
          }
        case '.':
          outputBytes.add(tape[ptr]);
        case ',':
          if (inputPtr < stdinBytes.length) {
            tape[ptr] = stdinBytes[inputPtr] % 256;
            inputPtr++;
          } else {
            tape[ptr] = 0;
          }
        case '[':
          if (tape[ptr] == 0) pc = bracketMap[pc]!;
        case ']':
          if (tape[ptr] != 0) pc = bracketMap[pc]!;
      }
      pc++;
    }

    // Декодировать байты как UTF-8
    try {
      return utf8.decode(outputBytes);
    } catch (_) {
      return String.fromCharCodes(outputBytes);
    }
  }

  Map<int, int> _buildBracketMap(String bfCode) {
    final stack = <int>[];
    final map = <int, int>{};

    for (int i = 0; i < bfCode.length; i++) {
      if (bfCode[i] == '[') {
        stack.add(i);
      } else if (bfCode[i] == ']') {
        if (stack.isEmpty) {
          throw BrainfuckError('Несбалансированная скобка ] на позиции $i');
        }
        final j = stack.removeLast();
        map[j] = i;
        map[i] = j;
      }
    }

    if (stack.isNotEmpty) {
      throw BrainfuckError(
        'Несбалансированная скобка [ на позиции ${stack.last}'
      );
    }
    return map;
  }
}

String runBf(String bfCode, {String stdin = '', int maxSteps = 1000000}) {
  return BrainfuckInterpreter(maxSteps: maxSteps).run(bfCode, stdin: stdin);
}
