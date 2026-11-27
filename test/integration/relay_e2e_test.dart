// Сквозная проверка против живого relay. По умолчанию пропускается.
//
//   flutter test test/integration --dart-define=E2E_RELAY=http://127.0.0.1:8787
//   flutter test test/integration --dart-define=E2E_RELAY=https://spoon-messenger-relay.nonospoon.workers.dev
//
// Каждое сообщение публикуется с минимальным TTL (60 с) на случайной доске.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/codec.dart';
import 'package:nospoon_app/core/envelope.dart';
import 'package:nospoon_app/transport/messenger.dart';
import 'package:nospoon_app/transport/relay_client.dart';

const _relay = String.fromEnvironment('E2E_RELAY');

String _randomKey() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
}

void main() {
  final skip = _relay.isEmpty ? 'E2E_RELAY не задан' : null;

  group('relay e2e', skip: skip, () {
    late SpoonMessenger messenger;
    final boardKey = _randomKey();

    setUpAll(() {
      messenger = SpoonMessenger(relay: RelayClient(relayUrl: _relay));
    });

    Future<String> read(String cid, {String? password, String? key}) async {
      final blob = await messenger.download(key ?? boardKey, cid);
      final opened = await MessageEnvelope.open(
        blob,
        boardKey: key ?? boardKey,
        password: password,
      );
      final decoded = SpoonCodec.decode(
        opened.spoonBin,
        createdAt: opened.createdAt,
        ttlSeconds: opened.ttlSeconds,
      );
      expect(decoded.success, isTrue, reason: decoded.error);
      return decoded.text;
    }

    test('отправка → лента → скачивание → расшифровка', () async {
      const text = 'there is no spoon · ложки нет';
      final sent = await messenger.send(text, boardKey, ttlSeconds: 60);
      expect(sent.cid, isNotEmpty);

      final feed = await messenger.feed(boardKey);
      expect(feed.map((e) => e.cid), contains(sent.cid));
      final entry = feed.firstWhere((e) => e.cid == sent.cid);
      expect(entry.expiresAt - entry.publishedAt, equals(60000));

      expect(await read(sent.cid), equals(text));
    });

    test('сообщение с паролем', () async {
      final sent = await messenger.send(
        'за семью печатями',
        boardKey,
        ttlSeconds: 60,
        password: 'сезам',
      );

      expect(await read(sent.cid, password: 'сезам'), equals('за семью печатями'));
      await expectLater(
        read(sent.cid, password: 'не сезам'),
        throwsA(isA<EnvelopeException>()
            .having((e) => e.error, 'error', EnvelopeError.wrongPassword)),
      );
      await expectLater(
        read(sent.cid),
        throwsA(isA<EnvelopeException>()
            .having((e) => e.error, 'error', EnvelopeError.passwordRequired)),
      );
    });

    test('чужая доска не видит ленту и не может скачать сообщение', () async {
      final sent = await messenger.send('только для своих', boardKey, ttlSeconds: 60);
      final stranger = _randomKey();

      expect(await messenger.feed(stranger), isEmpty);
      await expectLater(
        messenger.download(stranger, sent.cid),
        throwsA(isA<MessengerError>()),
      );
    });

    test('статистика отвечает', () async {
      final stats = await messenger.getStats();
      expect(stats.totalMessages, greaterThan(0));
      expect(stats.boards, greaterThan(0));
    });
  });
}
