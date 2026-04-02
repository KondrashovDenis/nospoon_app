// Высокоуровневый интерфейс Spoon Messenger
// Объединяет codec + IPFS + relay

import '../core/codec.dart';
import 'ipfs_client.dart';
import 'relay_client.dart';
import 'config.dart';

class MessengerError implements Exception {
  final String message;
  MessengerError(this.message);
  @override
  String toString() => 'MessengerError: $message';
}

class SendResult {
  final bool success;
  final String cid;
  final DateTime expiresAt;
  final int sizeBytes;
  final String circle;

  SendResult({
    required this.success,
    required this.cid,
    required this.expiresAt,
    required this.sizeBytes,
    required this.circle,
  });
}

class ReceivedMessage {
  final String cid;
  final String? text;
  final String? bfCode;
  final bool success;
  final String? error;
  final int publishedAt;
  final int? expiresAt;

  ReceivedMessage({
    required this.cid,
    this.text,
    this.bfCode,
    required this.success,
    this.error,
    required this.publishedAt,
    this.expiresAt,
  });
}

class SpoonMessenger {
  final IPFSClient ipfs;
  final RelayClient relay;

  SpoonMessenger({required this.ipfs, required this.relay});

  /// Фабричный метод — создать из конфига
  static Future<SpoonMessenger> create() async {
    final jwt = await TransportConfig.getPinataJwt();
    if (jwt == null) throw MessengerError('Pinata JWT не настроен');

    final relayUrl = await TransportConfig.getRelayUrl();

    return SpoonMessenger(
      ipfs: IPFSClient(jwt: jwt),
      relay: RelayClient(relayUrl: relayUrl),
    );
  }

  /// Отправить сообщение в круг
  Future<SendResult> send(
    String text,
    String circleKey, {
    int ttlSeconds = 86400,
    String? password,
  }) async {
    try {
      // Шаг 1: кодировать
      final encoded = SpoonCodec.encode(
        text,
        ttlSeconds: ttlSeconds,
        password: password,
      );

      // Шаг 2: загрузить в IPFS
      final cid = await ipfs.upload(
        encoded.binary,
        expiresAt: encoded.expiresAt.millisecondsSinceEpoch ~/ 1000,
      );

      // Шаг 3: опубликовать CID в relay
      await relay.publish(
        circleKey,
        cid,
        expiresAt: encoded.expiresAt.millisecondsSinceEpoch ~/ 1000,
      );

      return SendResult(
        success: true,
        cid: cid,
        expiresAt: encoded.expiresAt,
        sizeBytes: encoded.sizeBytes,
        circle: circleKey,
      );

    } catch (e) {
      throw MessengerError('Ошибка отправки: $e');
    }
  }

  /// Получить сообщения из круга
  Future<List<ReceivedMessage>> receive(
    String circleKey, {
    String? password,
  }) async {
    try {
      final entries = await relay.getFeed(circleKey);
      if (entries.isEmpty) return [];

      final results = <ReceivedMessage>[];

      for (final entry in entries) {
        try {
          final binary = await ipfs.download(entry.cid);
          final decoded = SpoonCodec.decode(
            binary,
            password: password,
          );

          results.add(ReceivedMessage(
            cid: entry.cid,
            text: decoded.success ? decoded.text : null,
            bfCode: decoded.bfCode,
            success: decoded.success,
            error: decoded.error,
            publishedAt: entry.publishedAt,
            expiresAt: entry.expiresAt,
          ));

        } catch (e) {
          results.add(ReceivedMessage(
            cid: entry.cid,
            success: false,
            error: e.toString(),
            publishedAt: entry.publishedAt,
            expiresAt: entry.expiresAt,
          ));
        }
      }
      return results;

    } catch (e) {
      throw MessengerError('Ошибка получения: $e');
    }
  }

  /// Статистика сети
  Future<NetworkStats> getStats() async {
    return relay.getStats();
  }
}
