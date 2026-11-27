/// TTL-обёртка на Brainfuck.
///
/// Программа читает один байт stdin (токен времени) и выполняет тело,
/// только если он совпал с зашитым в неё значением.
///
/// Это церемониальный слой: реальный срок жизни сообщения держат
/// зашифрованный заголовок конверта (envelope.dart) и relay, который
/// по истечении забывает запись и снимает файл с пина.
library;

/// Байт-токен для сообщения, созданного в [createdAt] со сроком [ttlSeconds].
/// Считается детерминированно из заголовка конверта — угадывать нечего.
int timeToken(DateTime createdAt, int ttlSeconds) {
  final seconds = createdAt.millisecondsSinceEpoch ~/ 1000;
  return (seconds ~/ ttlSeconds) % 256;
}

/// Токен в виде строки для stdin интерпретатора.
String stdinToken(DateTime createdAt, int ttlSeconds) =>
    String.fromCharCode(timeToken(createdAt, ttlSeconds));

/// Обернуть BF-программу в проверку токена.
String wrapWithTtl(
  String bfCode, {
  required DateTime createdAt,
  required int ttlSeconds,
}) {
  final token = timeToken(createdAt, ttlSeconds);

  final wrapper = StringBuffer();
  wrapper.write('+' * token);        // cell0 = ожидаемый токен
  wrapper.write('>,');               // cell1 = токен из stdin
  wrapper.write('<[->-<]>');         // cell1 -= cell0
  wrapper.write('>+');               // cell2 = 1
  wrapper.write('<[>-<[-]]>');       // если cell1 != 0: cell2 = 0
  wrapper.write('[');                // если совпало
  wrapper.write('[-]>');             // обнулить cell2, перейти в рабочую область
  wrapper.write(bfCode);             // выполнить тело
  wrapper.write(']');

  return wrapper.toString();
}
