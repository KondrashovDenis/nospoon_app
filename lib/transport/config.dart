// Конфигурация транспортного слоя
// API ключи хранятся в flutter_secure_storage

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransportConfig {
  static const _storage = FlutterSecureStorage();

  static const String _pinataJwtKey = 'pinata_jwt';
  static const String _relayUrlKey = 'relay_url';

  // Дефолтные значения (можно переопределить через настройки)
  static const String defaultRelayUrl =
      'https://spoon-messenger-relay.nonospoon.workers.dev';

  /// Сохранить Pinata JWT
  static Future<void> savePinataJwt(String jwt) async {
    await _storage.write(key: _pinataJwtKey, value: jwt);
  }

  /// Получить Pinata JWT
  static Future<String?> getPinataJwt() async {
    return await _storage.read(key: _pinataJwtKey);
  }

  /// Сохранить URL relay
  static Future<void> saveRelayUrl(String url) async {
    await _storage.write(key: _relayUrlKey, value: url);
  }

  /// Получить URL relay
  static Future<String> getRelayUrl() async {
    return await _storage.read(key: _relayUrlKey) ?? defaultRelayUrl;
  }

  /// Сохранить начальную конфигурацию при первом запуске
  static Future<void> initDefaults({required String pinataJwt}) async {
    final existing = await getPinataJwt();
    if (existing == null) {
      await savePinataJwt(pinataJwt);
    }
  }
}
