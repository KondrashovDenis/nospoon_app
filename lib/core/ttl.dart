/// TTL механика
/// Порт Python core/ttl.py на Dart

const int ttlPrecision = 3600; // 1 час вместо 60 секунд

int getTimeToken({DateTime? timestamp, int precision = ttlPrecision}) {
  final t = timestamp ?? DateTime.now();
  return t.millisecondsSinceEpoch ~/ 1000 ~/ precision;
}

/// Обернуть BF программу в TTL обёртку
(String, DateTime) wrapSimple(String bfCode, {int ttlSeconds = 3600}) {
  final now = DateTime.now();
  final expiresAt = now.add(Duration(seconds: ttlSeconds));
  final currentToken = getTimeToken(timestamp: now);
  final tokenVal = currentToken % 256;

  final ttlWrapper = StringBuffer();
  ttlWrapper.write('+' * tokenVal);  // cell0 = expected token
  ttlWrapper.write('>,' );           // cell1 = input token
  ttlWrapper.write('<[->-<]>');      // cell1 -= cell0
  ttlWrapper.write('>+');            // cell2 = 1
  ttlWrapper.write('<[>-<[-]]>');    // если cell1 != 0: cell2=0
  ttlWrapper.write('[');             // если совпало
  ttlWrapper.write('[-]>');         // обнулить cell2, перейти к рабочей области
  ttlWrapper.write(bfCode);         // выполнить оригинальный код
  ttlWrapper.write(']');

  return (ttlWrapper.toString(), expiresAt);
}

/// Получить токен для передачи в stdin
/// Пробуем текущий и предыдущий период — защита от граничных случаев
String getStdinToken({DateTime? timestamp}) {
  final token = getTimeToken(timestamp: timestamp);
  return String.fromCharCode(token % 256);
}

/// Получить все возможные токены для декодирования
/// Проверяем ±2 периода на случай расхождения часов
List<String> getAllValidTokens({DateTime? timestamp}) {
  final t = timestamp ?? DateTime.now();
  final current = getTimeToken(timestamp: t);

  final tokens = <String>[];
  for (int delta = -2; delta <= 2; delta++) {
    final token = (current + delta) % 256;
    final char = String.fromCharCode(token);
    if (!tokens.contains(char)) {
      tokens.add(char);
    }
  }
  return tokens;
}
