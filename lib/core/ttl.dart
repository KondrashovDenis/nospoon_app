/// TTL механика
/// Порт Python core/ttl.py на Dart

const int ttlPrecision = 60;

/// Получить временной токен
int getTimeToken({DateTime? timestamp, int precision = ttlPrecision}) {
  final t = timestamp ?? DateTime.now();
  return t.millisecondsSinceEpoch ~/ 1000 ~/ precision;
}

/// Обернуть BF программу в TTL обёртку
/// Возвращает (bfWithTtl, expiresAt)
(String, DateTime) wrapSimple(String bfCode, {int ttlSeconds = 3600}) {
  final now = DateTime.now();
  final expiresAt = now.add(Duration(seconds: ttlSeconds));
  final currentToken = getTimeToken(timestamp: now);
  final tokenVal = currentToken % 256;

  final expected = tokenVal;

  final ttlWrapper = StringBuffer();
  ttlWrapper.write('+' * expected);   // cell0 = expected token
  ttlWrapper.write('>,' );            // cell1 = input token
  ttlWrapper.write('<[->-<]>');       // cell1 -= cell0
  ttlWrapper.write('>+');             // cell2 = 1
  ttlWrapper.write('<[>-<[-]]>');     // если cell1 != 0: cell2=0
  ttlWrapper.write('[');              // если совпало
  ttlWrapper.write('[-]>');          // обнулить cell2, перейти к рабочей области
  ttlWrapper.write(bfCode);          // выполнить оригинальный код
  ttlWrapper.write(']');

  return (ttlWrapper.toString(), expiresAt);
}

/// Получить токен для передачи в stdin
String getStdinToken({DateTime? timestamp}) {
  final token = getTimeToken(timestamp: timestamp);
  return String.fromCharCode(token % 256);
}
