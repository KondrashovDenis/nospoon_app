/// Клиент relay (Cloudflare Worker), протокол v2.
///
/// Через relay идёт всё: публикация, лента, скачивание. Ключей хранилища
/// в приложении нет. Доска адресуется хешем ключа — см. MessageEnvelope.boardId.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class RelayError implements Exception {
  final String message;
  RelayError(this.message);

  @override
  String toString() => 'RelayError: $message';
}

class FeedEntry {
  final String cid;

  /// Время публикации и истечения по часам relay, мс.
  final int publishedAt;
  final int expiresAt;

  FeedEntry({
    required this.cid,
    required this.publishedAt,
    required this.expiresAt,
  });

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    return FeedEntry(
      cid: json['cid'] as String,
      publishedAt: json['published_at'] as int,
      expiresAt: json['expires_at'] as int,
    );
  }
}

class NetworkStats {
  final int totalMessages;
  final int boards;
  final int updatedAt;

  NetworkStats({
    required this.totalMessages,
    required this.boards,
    required this.updatedAt,
  });

  factory NetworkStats.fromJson(Map<String, dynamic> json) {
    return NetworkStats(
      totalMessages: json['total_messages'] as int? ?? 0,
      boards: json['boards'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? 0,
    );
  }
}

class RelayClient {
  final String relayUrl;
  final http.Client _http;

  RelayClient({required this.relayUrl, http.Client? client})
      : _http = client ?? http.Client();

  /// Опубликовать конверт на доске. Возвращает запись ленты с CID.
  Future<FeedEntry> publish(
    String boardId,
    Uint8List envelope, {
    required int ttlSeconds,
  }) async {
    final response = await _send(
      () => _http
          .post(
            Uri.parse('$relayUrl/v2/board/$boardId/publish?ttl=$ttlSeconds'),
            headers: {'Content-Type': 'application/octet-stream'},
            body: envelope,
          )
          .timeout(const Duration(seconds: 40)),
    );
    _check(response);
    return FeedEntry.fromJson(_json(response));
  }

  /// Активные сообщения доски, новые первыми.
  Future<List<FeedEntry>> getFeed(String boardId) async {
    final response = await _send(
      () => _http
          .get(Uri.parse('$relayUrl/v2/board/$boardId/feed'))
          .timeout(const Duration(seconds: 15)),
    );
    _check(response);
    final entries = _json(response)['entries'] as List<dynamic>? ?? [];
    return entries
        .map((e) => FeedEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Скачать конверт сообщения.
  Future<Uint8List> download(String boardId, String cid) async {
    final response = await _send(
      () => _http
          .get(Uri.parse('$relayUrl/v2/board/$boardId/blob/$cid'))
          .timeout(const Duration(seconds: 30)),
    );
    _check(response);
    return response.bodyBytes;
  }

  Future<NetworkStats> getStats() async {
    final response = await _send(
      () => _http
          .get(Uri.parse('$relayUrl/stats'))
          .timeout(const Duration(seconds: 10)),
    );
    _check(response);
    return NetworkStats.fromJson(_json(response));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (_) {
      throw RelayError('relay unreachable');
    }
  }

  void _check(http.Response response) {
    if (response.statusCode == 200) return;

    String? code;
    try {
      code = (jsonDecode(response.body) as Map<String, dynamic>)['error']
          as String?;
    } catch (_) {
      // тело не JSON — покажем только статус
    }

    throw RelayError(switch (code) {
      'rate_limited' => 'too many requests, wait a minute',
      'too_large' => 'message too large',
      'not_found' => 'message expired or not found',
      'storage_not_configured' || 'storage_error' => 'storage unavailable',
      _ => 'relay error ${response.statusCode}',
    });
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw RelayError('bad relay response');
    }
  }
}
