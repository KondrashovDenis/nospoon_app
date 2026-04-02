/// Конфигурация транспортного слоя
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransportConfig {
  static const _storage = FlutterSecureStorage();

  static const String _pinataJwtKey = 'pinata_jwt';
  static const String _relayUrlKey = 'relay_url';

  static const String defaultRelayUrl =
      'https://spoon-messenger-relay.nonospoon.workers.dev';

  // JWT вшит в приложение для первого запуска
  // В продакшене — получать через onboarding
  static const String _defaultPinataJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJmNjY4MTZlZC0wY2NlLTQ2YzgtOWE4OS0xMWIzYjhlNTM2MGIiLCJlbWFpbCI6ImRlbmNpYW9waW5AZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjEsImlkIjoiRlJBMSJ9LHsiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjEsImlkIjoiTllDMSJ9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZSwic3RhdHVzIjoiQUNUSVZFIn0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6ImUyN2Q3YTQzN2RiZjhkODUwNjgxIiwic2NvcGVkS2V5U2VjcmV0IjoiZDg0NTQxMWY1ZjFkYmZlODM1YmIxMzlkNTlmMzc3ODIzOGVjMmM3MzQ0OTkyY2JmMWM0ZDEwNTQ2ODZhNGMyYyIsImV4cCI6MTgwNjY0MjQ5OH0.FdfaWsOmD2_Ju-g7exVropycMPt7cEi-ajxab32jJN4';

  static Future<void> savePinataJwt(String jwt) async {
    await _storage.write(key: _pinataJwtKey, value: jwt);
  }

  static Future<String?> getPinataJwt() async {
    final stored = await _storage.read(key: _pinataJwtKey);
    if (stored != null) return stored;
    // вернуть дефолтный если не сохранён
    if (_defaultPinataJwt != 'PINATA_JWT_PLACEHOLDER') {
      return _defaultPinataJwt;
    }
    return null;
  }

  static Future<void> saveRelayUrl(String url) async {
    await _storage.write(key: _relayUrlKey, value: url);
  }

  static Future<String> getRelayUrl() async {
    return await _storage.read(key: _relayUrlKey) ?? defaultRelayUrl;
  }

  static Future<void> initDefaults({required String pinataJwt}) async {
    final existing = await getPinataJwt();
    if (existing == null) {
      await savePinataJwt(pinataJwt);
    }
  }
}
