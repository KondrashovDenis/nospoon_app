// Cloudflare Workers relay клиент
// Публикация и получение CID по ключу круга

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RelayError implements Exception {
  final String message;
  RelayError(this.message);
  @override
  String toString() => 'RelayError: $message';
}

class CircleEntry {
  final String cid;
  final int publishedAt;
  final int? expiresAt;

  CircleEntry({
    required this.cid,
    required this.publishedAt,
    this.expiresAt,
  });

  factory CircleEntry.fromJson(Map<String, dynamic> json) {
    return CircleEntry(
      cid: json['cid'] as String,
      publishedAt: json['published_at'] as int,
      expiresAt: json['expires_at'] as int?,
    );
  }
}

class NetworkStats {
  final int totalMessages;
  final int updatedAt;

  NetworkStats({required this.totalMessages, required this.updatedAt});

  factory NetworkStats.fromJson(Map<String, dynamic> json) {
    return NetworkStats(
      totalMessages: json['total_messages'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? 0,
    );
  }
}

class RelayClient {
  final String relayUrl;

  RelayClient({required this.relayUrl});

  /// Опубликовать CID в круг
  Future<bool> publish(
    String circleKey,
    String cid, {
    int? expiresAt,
  }) async {
    try {
      final url = '$relayUrl/circle/$circleKey/publish';
      final body = <String, dynamic>{'cid': cid};
      // убрать expires_at — Worker некорректно обрабатывает
      // if (expiresAt != null) body['expires_at'] = expiresAt;

      debugPrint('=== RELAY PUBLISH ===');
      debugPrint('url: $url');
      debugPrint('body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint('status: ${response.statusCode}');
      debugPrint('response: ${response.body}');

      if (response.statusCode != 200) {
        throw RelayError('Ошибка публикации: ${response.statusCode} ${response.body}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['success'] as bool? ?? false;

    } catch (e) {
      debugPrint('=== RELAY PUBLISH ERROR ===');
      debugPrint(e.toString());
      if (e is RelayError) rethrow;
      throw RelayError('Ошибка публикации CID: $e');
    }
  }

  /// Получить список CID для круга
  Future<List<CircleEntry>> getFeed(String circleKey) async {
    try {
      final url = '$relayUrl/circle/$circleKey/feed';

      debugPrint('=== RELAY GET FEED ===');
      debugPrint('url: $url');

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      debugPrint('status: ${response.statusCode}');
      debugPrint('response: ${response.body}');

      if (response.statusCode != 200) {
        throw RelayError('Ошибка получения feed: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = json['entries'] as List<dynamic>? ?? [];

      debugPrint('entries count: ${entries.length}');

      return entries
          .map((e) => CircleEntry.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      debugPrint('=== RELAY GET FEED ERROR ===');
      debugPrint(e.toString());
      if (e is RelayError) rethrow;
      throw RelayError('Ошибка получения feed: $e');
    }
  }

  /// Получить статистику сети
  Future<NetworkStats> getStats() async {
    try {
      final url = '$relayUrl/stats';
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw RelayError('Ошибка получения stats: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return NetworkStats.fromJson(json);

    } catch (e) {
      if (e is RelayError) rethrow;
      throw RelayError('Ошибка получения stats: $e');
    }
  }
}
