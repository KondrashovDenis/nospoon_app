import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nospoon_app/core/envelope.dart';
import 'package:nospoon_app/transport/messenger.dart';
import 'package:nospoon_app/transport/relay_client.dart';

void main() {
  const relayUrl = 'https://relay.test';
  const boardKey = 's3cr3tb0ardk3ys3cr3tb0ar';

  group('RelayClient', () {
    test('publish шлёт байты конверта на /v2/board/<id>/publish?ttl=', () async {
      late http.Request seen;
      final client = RelayClient(
        relayUrl: relayUrl,
        client: MockClient((request) async {
          seen = request;
          return http.Response(
            jsonEncode({'success': true, 'cid': 'QmTest', 'published_at': 1000, 'expires_at': 61000}),
            200,
          );
        }),
      );

      final entry = await client.publish(
        'a' * 32,
        Uint8List.fromList([1, 2, 3]),
        ttlSeconds: 60,
      );

      expect(seen.method, equals('POST'));
      expect(seen.url.path, equals('/v2/board/${'a' * 32}/publish'));
      expect(seen.url.queryParameters['ttl'], equals('60'));
      expect(seen.bodyBytes, equals([1, 2, 3]));
      expect(entry.cid, equals('QmTest'));
      expect(entry.expiresAt, equals(61000));
    });

    test('getFeed разбирает записи', () async {
      final client = RelayClient(
        relayUrl: relayUrl,
        client: MockClient((request) async {
          expect(request.url.path, equals('/v2/board/${'b' * 32}/feed'));
          return http.Response(
            jsonEncode({
              'count': 2,
              'entries': [
                {'cid': 'Qm1', 'published_at': 2000, 'expires_at': 9000},
                {'cid': 'Qm2', 'published_at': 1000, 'expires_at': 8000},
              ],
            }),
            200,
          );
        }),
      );

      final feed = await client.getFeed('b' * 32);
      expect(feed.map((e) => e.cid), equals(['Qm1', 'Qm2']));
      expect(feed.first.publishedAt, equals(2000));
    });

    test('download возвращает байты', () async {
      final client = RelayClient(
        relayUrl: relayUrl,
        client: MockClient((request) async {
          expect(request.url.path, equals('/v2/board/${'c' * 32}/blob/QmX'));
          return http.Response.bytes([9, 8, 7], 200);
        }),
      );
      expect(await client.download('c' * 32, 'QmX'), equals([9, 8, 7]));
    });

    test('коды ошибок relay превращаются в понятные сообщения', () async {
      Future<String> errorFor(int status, String code) async {
        final client = RelayClient(
          relayUrl: relayUrl,
          client: MockClient(
            (_) async => http.Response(jsonEncode({'error': code}), status),
          ),
        );
        try {
          await client.getFeed('d' * 32);
          return 'no error';
        } on RelayError catch (e) {
          return e.message;
        }
      }

      expect(await errorFor(429, 'rate_limited'), contains('too many'));
      expect(await errorFor(413, 'too_large'), contains('too large'));
      expect(await errorFor(404, 'not_found'), contains('expired'));
      expect(await errorFor(503, 'storage_not_configured'), contains('storage'));
      expect(await errorFor(500, 'internal_error'), contains('500'));
    });

    test('сетевой сбой не раскрывает адрес и идентификатор доски', () async {
      final client = RelayClient(
        relayUrl: relayUrl,
        client: MockClient((request) async {
          throw http.ClientException('Connection failed', request.url);
        }),
      );
      try {
        await client.getFeed('e' * 32);
        fail('ожидалась ошибка');
      } on RelayError catch (e) {
        expect(e.message, equals('relay unreachable'));
        expect(e.toString().contains('e' * 32), isFalse);
      }
    });
  });

  group('SpoonMessenger', () {
    test('send: на relay уходит хеш ключа и шифротекст, а не ключ и текст', () async {
      late http.Request seen;
      final messenger = SpoonMessenger(
        relay: RelayClient(
          relayUrl: relayUrl,
          client: MockClient((request) async {
            seen = request;
            return http.Response(
              jsonEncode({'success': true, 'cid': 'QmSent', 'published_at': 5, 'expires_at': 3600005}),
              200,
            );
          }),
        ),
      );

      const text = 'совершенно секретно';
      final result = await messenger.send(text, boardKey, ttlSeconds: 3600);

      expect(result.cid, equals('QmSent'));
      expect(seen.url.toString().contains(boardKey), isFalse);
      expect(seen.url.path, contains(await MessageEnvelope.boardId(boardKey)));
      expect(seen.bodyBytes.sublist(0, 4), equals(MessageEnvelope.magic));
      expect(latin1.decode(seen.bodyBytes).contains(boardKey), isFalse);

      // получатель с ключом доски читает то, что ушло
      final opened = await MessageEnvelope.open(seen.bodyBytes, boardKey: boardKey);
      expect(opened.ttlSeconds, equals(3600));
    });

    test('ошибка relay доходит как MessengerError без технических деталей', () async {
      final messenger = SpoonMessenger(
        relay: RelayClient(
          relayUrl: relayUrl,
          client: MockClient(
            (_) async => http.Response(jsonEncode({'error': 'rate_limited'}), 429),
          ),
        ),
      );
      expect(
        messenger.feed(boardKey),
        throwsA(isA<MessengerError>().having((e) => e.message, 'message', contains('too many'))),
      );
    });
  });
}
