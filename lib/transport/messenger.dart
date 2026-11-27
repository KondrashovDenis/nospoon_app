/// Высокоуровневый интерфейс: кодек + конверт + relay.
library;

import 'dart:typed_data';

import '../core/codec.dart';
import '../core/envelope.dart';
import 'config.dart';
import 'relay_client.dart';

class MessengerError implements Exception {
  final String message;
  MessengerError(this.message);

  @override
  String toString() => message;
}

class SendResult {
  final String cid;
  final DateTime expiresAt;
  final int sizeBytes;

  SendResult({
    required this.cid,
    required this.expiresAt,
    required this.sizeBytes,
  });
}

class SpoonMessenger {
  final RelayClient relay;

  SpoonMessenger({required this.relay});

  factory SpoonMessenger.create() {
    return SpoonMessenger(
      relay: RelayClient(relayUrl: TransportConfig.relayUrl),
    );
  }

  /// Закодировать, зашифровать и опубликовать сообщение на доске.
  Future<SendResult> send(
    String text,
    String boardKey, {
    int ttlSeconds = 86400,
    String? password,
  }) async {
    try {
      final createdAt = DateTime.now();
      final encoded = SpoonCodec.encode(
        text,
        createdAt: createdAt,
        ttlSeconds: ttlSeconds,
      );
      final envelope = await MessageEnvelope.seal(
        spoonBin: encoded.binary,
        boardKey: boardKey,
        createdAt: createdAt,
        ttlSeconds: ttlSeconds,
        password: password,
      );

      final entry = await relay.publish(
        await MessageEnvelope.boardId(boardKey),
        envelope,
        ttlSeconds: ttlSeconds,
      );

      return SendResult(
        cid: entry.cid,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(entry.expiresAt),
        sizeBytes: envelope.length,
      );
    } on RelayError catch (e) {
      throw MessengerError(e.message);
    }
  }

  /// Лента доски: только метаданные, содержимое качается по требованию.
  Future<List<FeedEntry>> feed(String boardKey) async {
    try {
      return await relay.getFeed(await MessageEnvelope.boardId(boardKey));
    } on RelayError catch (e) {
      throw MessengerError(e.message);
    }
  }

  /// Скачать конверт сообщения.
  Future<Uint8List> download(String boardKey, String cid) async {
    try {
      return await relay.download(await MessageEnvelope.boardId(boardKey), cid);
    } on RelayError catch (e) {
      throw MessengerError(e.message);
    }
  }

  Future<NetworkStats> getStats() => relay.getStats();
}
