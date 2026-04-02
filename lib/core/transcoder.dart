/// Brainfuck → Spoon перекодировщик
/// Порт Python core/transcoder.py на Dart

import 'dart:typed_data';

class SpoonTranscoder {
  static const Map<String, String> bfToSpoon = {
    '+': '1',
    '-': '000',
    '>': '010',
    '<': '0110',
    '[': '00110',
    ']': '0111',
    '.': '001110',
    ',': '0011110',
  };

  static final Map<String, String> spoonToBf = {
    for (final e in bfToSpoon.entries) e.value: e.key
  };

  /// BF код → Spoon битовая строка
  static String bfToSpoonBits(String bfCode) {
    final result = StringBuffer();
    for (final char in bfCode.split('')) {
      if (bfToSpoon.containsKey(char)) {
        result.write(bfToSpoon[char]);
      }
    }
    return result.toString();
  }

  /// Spoon битовая строка → BF код
  static String spoonBitsToBf(String bits) {
    final result = StringBuffer();
    int i = 0;
    while (i < bits.length) {
      bool matched = false;
      for (int length = 1; length <= 7; length++) {
        if (i + length > bits.length) break;
        final prefix = bits.substring(i, i + length);
        if (spoonToBf.containsKey(prefix)) {
          result.write(spoonToBf[prefix]);
          i += length;
          matched = true;
          break;
        }
      }
      if (!matched) i++;
    }
    return result.toString();
  }

  /// Битовая строка → байты с 4-байтным заголовком длины
  static Uint8List bitsToBytes(String bits) {
    final length = bits.length;
    final padding = (8 - length % 8) % 8;
    final padded = bits + '0' * padding;

    final byteCount = padded.length ~/ 8;
    final result = Uint8List(4 + byteCount);

    // 4-байтный заголовок — длина битовой строки
    result[0] = (length >> 24) & 0xFF;
    result[1] = (length >> 16) & 0xFF;
    result[2] = (length >> 8) & 0xFF;
    result[3] = length & 0xFF;

    for (int i = 0; i < byteCount; i++) {
      result[4 + i] = int.parse(padded.substring(i * 8, i * 8 + 8), radix: 2);
    }
    return result;
  }

  /// Байты → битовая строка (с учётом заголовка)
  static String bytesToBits(Uint8List data) {
    // читать длину из заголовка
    final length = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];

    final bits = StringBuffer();
    for (int i = 4; i < data.length; i++) {
      bits.write(data[i].toRadixString(2).padLeft(8, '0'));
    }
    return bits.toString().substring(0, length);
  }

  /// BF код → .bin байты
  static Uint8List encodeToBin(String bfCode) {
    final bits = bfToSpoonBits(bfCode);
    return bitsToBytes(bits);
  }

  /// .bin байты → BF код
  static String decodeFromBin(Uint8List data) {
    final bits = bytesToBits(data);
    return spoonBitsToBf(bits);
  }
}
