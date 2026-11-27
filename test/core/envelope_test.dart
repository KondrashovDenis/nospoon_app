import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/codec.dart';
import 'package:nospoon_app/core/envelope.dart';

void main() {
  const boardKey = 'k3y0fth3b0ardk3y0fth3b0a';
  const otherKey = 'an0th3rb0ardan0th3rb0ard';
  const ttl = 3600;
  final createdAt = DateTime.utc(2026, 11, 27, 12, 0, 0);
  final fresh = createdAt.add(const Duration(minutes: 10));

  Uint8List spoon(String text) =>
      SpoonCodec.encode(text, createdAt: createdAt, ttlSeconds: ttl).binary;

  Future<Uint8List> seal(String text, {String? password, String key = boardKey}) {
    return MessageEnvelope.seal(
      spoonBin: spoon(text),
      boardKey: key,
      createdAt: createdAt,
      ttlSeconds: ttl,
      password: password,
    );
  }

  Matcher throwsEnvelope(EnvelopeError error) => throwsA(
        isA<EnvelopeException>().having((e) => e.error, 'error', error),
      );

  group('boardId', () {
    test('детерминирован, 32 hex, не содержит ключ', () async {
      final id = await MessageEnvelope.boardId(boardKey);
      expect(id, equals(await MessageEnvelope.boardId(boardKey)));
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(id.contains(boardKey), isFalse);
    });

    test('разные ключи — разные адреса', () async {
      expect(
        await MessageEnvelope.boardId(boardKey),
        isNot(equals(await MessageEnvelope.boardId(otherKey))),
      );
    });
  });

  group('без пароля', () {
    test('roundtrip: текст, время и TTL восстанавливаются', () async {
      final blob = await seal('Привет, мир');
      expect(MessageEnvelope.needsPassword(blob), isFalse);

      final opened = await MessageEnvelope.open(blob, boardKey: boardKey, now: fresh);
      expect(opened.createdAt.millisecondsSinceEpoch, equals(createdAt.millisecondsSinceEpoch));
      expect(opened.ttlSeconds, equals(ttl));

      final decoded = SpoonCodec.decode(
        opened.spoonBin,
        createdAt: opened.createdAt,
        ttlSeconds: opened.ttlSeconds,
      );
      expect(decoded.text, equals('Привет, мир'));
    });

    test('конверт не содержит открытого Spoon-.bin', () async {
      final bin = spoon('Hello, spoon');
      final blob = await seal('Hello, spoon');
      final hay = blob.join(',');
      final needle = bin.sublist(4, 16).join(','); // 12 байт подряд из .bin
      expect(hay.contains(needle), isFalse);
    });

    test('два конверта одного текста различаются (случайный nonce)', () async {
      expect(await seal('same'), isNot(equals(await seal('same'))));
    });

    test('чужой ключ доски — corrupted', () async {
      final blob = await seal('secret');
      expect(
        MessageEnvelope.open(blob, boardKey: otherKey, now: fresh),
        throwsEnvelope(EnvelopeError.corrupted),
      );
    });

    test('изменённый байт шифротекста — corrupted', () async {
      final blob = await seal('secret');
      blob[blob.length - 20] ^= 0x01;
      expect(
        MessageEnvelope.open(blob, boardKey: boardKey, now: fresh),
        throwsEnvelope(EnvelopeError.corrupted),
      );
    });

    test('подделка флага в заголовке не проходит', () async {
      final blob = await seal('secret');
      blob[4] = MessageEnvelope.flagPassword; // «теперь с паролем»
      // заголовок входит в associated data — сообщение не откроется никак
      await expectLater(
        MessageEnvelope.open(blob, boardKey: boardKey, password: 'x', now: fresh),
        throwsA(isA<EnvelopeException>()),
      );
    });
  });

  group('срок жизни', () {
    test('ровно в момент истечения — expired', () async {
      final blob = await seal('short lived');
      final expiry = createdAt.add(const Duration(seconds: ttl));

      final justBefore = expiry.subtract(const Duration(milliseconds: 1));
      await MessageEnvelope.open(blob, boardKey: boardKey, now: justBefore);

      expect(
        MessageEnvelope.open(blob, boardKey: boardKey, now: expiry),
        throwsEnvelope(EnvelopeError.expired),
      );
    });

    test('после истечения сообщение не «воскресает»', () async {
      final blob = await seal('gone');
      // старая схема снова открывала сообщение через 256 периодов и при совпадении токенов
      for (final hours in [2, 3, 6, 24, 256, 257, 24 * 30]) {
        expect(
          MessageEnvelope.open(
            blob,
            boardKey: boardKey,
            now: createdAt.add(Duration(hours: hours)),
          ),
          throwsEnvelope(EnvelopeError.expired),
          reason: '+$hours ч',
        );
      }
    });
  });

  group('с паролем', () {
    late Uint8List blob;
    final watch = Stopwatch();

    setUpAll(() async {
      watch.start();
      blob = await seal('Секретное послание', password: 'пароль-123');
      watch.stop();
      // ignore: avoid_print
      print('seal с Argon2id: ${watch.elapsedMilliseconds} мс');
    });

    test('флаг пароля виден без расшифровки', () {
      expect(MessageEnvelope.needsPassword(blob), isTrue);
    });

    test('без пароля — passwordRequired', () {
      expect(
        MessageEnvelope.open(blob, boardKey: boardKey, now: fresh),
        throwsEnvelope(EnvelopeError.passwordRequired),
      );
    });

    test('верный пароль открывает', () async {
      final opened = await MessageEnvelope.open(
        blob,
        boardKey: boardKey,
        password: 'пароль-123',
        now: fresh,
      );
      final decoded = SpoonCodec.decode(
        opened.spoonBin,
        createdAt: opened.createdAt,
        ttlSeconds: opened.ttlSeconds,
      );
      expect(decoded.text, equals('Секретное послание'));
    });

    test('неверный пароль — wrongPassword', () {
      expect(
        MessageEnvelope.open(blob, boardKey: boardKey, password: 'пароль-124', now: fresh),
        throwsEnvelope(EnvelopeError.wrongPassword),
      );
    });

    test('верный пароль, но чужая доска — не открывается', () {
      expect(
        MessageEnvelope.open(blob, boardKey: otherKey, password: 'пароль-123', now: fresh),
        throwsEnvelope(EnvelopeError.wrongPassword),
      );
    });

    test('перебор коротких паролей не даёт ложных срабатываний', () async {
      // у старого 8-битного хеша совпадал в среднем каждый 256-й пароль
      final quick = await seal('x', password: 'right');
      var opened = 0;
      for (var i = 0; i < 6; i++) {
        try {
          await MessageEnvelope.open(quick, boardKey: boardKey, password: 'wrong$i', now: fresh);
          opened++;
        } on EnvelopeException {
          // ожидаемо
        }
      }
      expect(opened, equals(0));
    });
  });

  group('не конверт', () {
    test('пустые и обрезанные данные — malformed', () {
      for (final data in [
        Uint8List(0),
        Uint8List.fromList([0x4E, 0x53, 0x50]),
        Uint8List.fromList([0x4E, 0x53, 0x50, 0x32, 0x00, 1, 2, 3]),
      ]) {
        expect(
          MessageEnvelope.open(data, boardKey: boardKey, now: fresh),
          throwsEnvelope(EnvelopeError.malformed),
        );
        expect(() => MessageEnvelope.needsPassword(data), throwsA(isA<EnvelopeException>()));
      }
    });

    test('старый формат (голый Spoon-.bin) — malformed', () {
      expect(
        MessageEnvelope.open(spoon('legacy'), boardKey: boardKey, now: fresh),
        throwsEnvelope(EnvelopeError.malformed),
      );
    });

    test('неизвестные флаги — malformed', () async {
      final blob = await seal('x');
      blob[4] = 0x80;
      expect(
        MessageEnvelope.open(blob, boardKey: boardKey, now: fresh),
        throwsEnvelope(EnvelopeError.malformed),
      );
    });
  });
}
