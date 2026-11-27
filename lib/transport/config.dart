/// Конфигурация транспортного слоя.
///
/// Секретов в приложении нет: ключ хранилища живёт на стороне relay.
library;

class TransportConfig {
  /// Адрес relay. Для отладки переопределяется при сборке:
  /// `--dart-define=RELAY_URL=http://127.0.0.1:8787`
  static const String relayUrl = String.fromEnvironment(
    'RELAY_URL',
    defaultValue: 'https://spoon-messenger-relay.nonospoon.workers.dev',
  );
}
