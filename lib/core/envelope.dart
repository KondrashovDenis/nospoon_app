/// Конверт сообщения NSP2 — шифрование поверх Spoon-.bin.
///
/// Spoon — кодирование, его читает любой. Защиту даёт этот слой:
/// XChaCha20-Poly1305 с ключом, выведенным из ключа доски. Без ключа доски
/// ни relay, ни хранилище, ни тот, кто узнал CID, текст не прочтут.
/// Пароль сообщения — второй слой: Argon2id(пароль) подмешивается в ключ,
/// неверный пароль не расшифровывает, а не просто скрывает текст в UI.
///
/// Формат (все числа big-endian):
///   0   4   magic "NSP2"
///   4   1   flags: бит 0 — сообщение с паролем
///   5   16  salt Argon2id            — только при бите 0
///   ..  24  nonce XChaCha20
///   ..  N   шифротекст
///   ..  16  MAC Poly1305
///
/// Всё до nonce — associated data, подделка заголовка ломает MAC.
/// Открытый текст: created_at (u64, мс) · ttl (u32, сек) · Spoon-.bin.
library;

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

enum EnvelopeError {
  /// Сообщение с паролем, пароль не передан.
  passwordRequired,

  /// MAC не сошёлся у сообщения с паролем.
  wrongPassword,

  /// MAC не сошёлся: чужой ключ доски либо данные повреждены.
  corrupted,

  /// Срок жизни истёк.
  expired,

  /// Это не конверт NSP2.
  malformed,
}

class EnvelopeException implements Exception {
  final EnvelopeError error;
  const EnvelopeException(this.error);

  @override
  String toString() => 'EnvelopeException: ${error.name}';
}

class OpenedMessage {
  final Uint8List spoonBin;
  final DateTime createdAt;
  final int ttlSeconds;

  const OpenedMessage({
    required this.spoonBin,
    required this.createdAt,
    required this.ttlSeconds,
  });

  DateTime get expiresAt => createdAt.add(Duration(seconds: ttlSeconds));
}

class MessageEnvelope {
  static const List<int> magic = [0x4E, 0x53, 0x50, 0x32]; // "NSP2"
  static const int flagPassword = 0x01;

  static const int _saltLength = 16;
  static const int _nonceLength = 24;
  static const int _macLength = 16;
  static const int _innerHeaderLength = 12;
  static const String _context = 'nospoon/v2';

  // Argon2id: минимум из рекомендаций OWASP (19 МиБ, 2 прохода).
  // Реализация на чистом Dart, поэтому параметры умеренные —
  // иначе открытие сообщения на телефоне занимает секунды.
  static const int _argonMemoryKiB = 19456;
  static const int _argonIterations = 2;
  static const int _argonParallelism = 1;

  static final _aead = Xchacha20.poly1305Aead();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _rng = Random.secure();

  /// Адрес доски на relay: хеш ключа. Сам ключ на сервер не уходит.
  static Future<String> boardId(String boardKey) async {
    final hash = await Sha256().hash(
      utf8.encode('$_context/board-id:$boardKey'),
    );
    return hash.bytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Нужен ли пароль, чтобы открыть конверт. Бросает malformed для не-конверта.
  static bool needsPassword(Uint8List blob) => _parse(blob).hasPassword;

  /// Зашифровать Spoon-.bin в конверт.
  static Future<Uint8List> seal({
    required Uint8List spoonBin,
    required String boardKey,
    required DateTime createdAt,
    required int ttlSeconds,
    String? password,
  }) async {
    if (boardKey.isEmpty) throw ArgumentError('Пустой ключ доски');
    if (ttlSeconds <= 0) throw ArgumentError('TTL должен быть положительным');

    final hasPassword = password != null && password.isNotEmpty;

    final header = BytesBuilder()
      ..add(magic)
      ..addByte(hasPassword ? flagPassword : 0);

    List<int>? passwordKey;
    if (hasPassword) {
      final salt = _randomBytes(_saltLength);
      header.add(salt);
      passwordKey = await _derivePasswordKey(password, salt);
    }
    final aad = header.toBytes();

    final inner = ByteData(_innerHeaderLength)
      ..setUint64(0, createdAt.millisecondsSinceEpoch)
      ..setUint32(8, ttlSeconds);
    final plain = BytesBuilder()
      ..add(inner.buffer.asUint8List())
      ..add(spoonBin);

    final nonce = _randomBytes(_nonceLength);
    final box = await _aead.encrypt(
      plain.toBytes(),
      secretKey: await _messageKey(boardKey, passwordKey),
      nonce: nonce,
      aad: aad,
    );

    final out = BytesBuilder()
      ..add(aad)
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  /// Расшифровать конверт. Бросает [EnvelopeException].
  static Future<OpenedMessage> open(
    Uint8List blob, {
    required String boardKey,
    String? password,
    DateTime? now,
  }) async {
    final parsed = _parse(blob);

    List<int>? passwordKey;
    if (parsed.hasPassword) {
      if (password == null || password.isEmpty) {
        throw const EnvelopeException(EnvelopeError.passwordRequired);
      }
      passwordKey = await _derivePasswordKey(password, parsed.salt!);
    }

    List<int> plain;
    try {
      plain = await _aead.decrypt(
        SecretBox(parsed.cipherText, nonce: parsed.nonce, mac: Mac(parsed.mac)),
        secretKey: await _messageKey(boardKey, passwordKey),
        aad: parsed.aad,
      );
    } on SecretBoxAuthenticationError {
      throw EnvelopeException(
        parsed.hasPassword
            ? EnvelopeError.wrongPassword
            : EnvelopeError.corrupted,
      );
    }

    if (plain.length <= _innerHeaderLength) {
      throw const EnvelopeException(EnvelopeError.malformed);
    }

    final bytes = Uint8List.fromList(plain);
    final inner = ByteData.sublistView(bytes, 0, _innerHeaderLength);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(inner.getUint64(0));
    final ttlSeconds = inner.getUint32(8);
    if (ttlSeconds == 0) {
      throw const EnvelopeException(EnvelopeError.malformed);
    }

    final message = OpenedMessage(
      spoonBin: bytes.sublist(_innerHeaderLength),
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );

    if (!(now ?? DateTime.now()).isBefore(message.expiresAt)) {
      throw const EnvelopeException(EnvelopeError.expired);
    }
    return message;
  }

  // ── Внутреннее ─────────────────────────────────────────────

  static _Parsed _parse(Uint8List blob) {
    const malformed = EnvelopeException(EnvelopeError.malformed);

    if (blob.length < magic.length + 1) throw malformed;
    for (var i = 0; i < magic.length; i++) {
      if (blob[i] != magic[i]) throw malformed;
    }

    final flags = blob[magic.length];
    if (flags & ~flagPassword != 0) throw malformed;
    final hasPassword = flags & flagPassword != 0;

    var offset = magic.length + 1;
    Uint8List? salt;
    if (hasPassword) {
      if (blob.length < offset + _saltLength) throw malformed;
      salt = blob.sublist(offset, offset + _saltLength);
      offset += _saltLength;
    }
    final aadEnd = offset;

    if (blob.length < offset + _nonceLength + _macLength + 1) throw malformed;
    final nonce = blob.sublist(offset, offset + _nonceLength);
    offset += _nonceLength;

    final macStart = blob.length - _macLength;
    return _Parsed(
      hasPassword: hasPassword,
      salt: salt,
      aad: blob.sublist(0, aadEnd),
      nonce: nonce,
      cipherText: blob.sublist(offset, macStart),
      mac: blob.sublist(macStart),
    );
  }

  /// Ключ сообщения: HKDF от ключа доски, при наличии пароля — ещё и от него.
  static Future<SecretKey> _messageKey(
    String boardKey,
    List<int>? passwordKey,
  ) {
    return _hkdf.deriveKey(
      secretKey: SecretKey([...?passwordKey, ...utf8.encode(boardKey)]),
      nonce: utf8.encode(_context),
      info: utf8.encode(passwordKey == null ? 'message' : 'message+password'),
    );
  }

  /// Argon2id считается в отдельном изоляте, чтобы не замирал интерфейс.
  static Future<List<int>> _derivePasswordKey(String password, List<int> salt) {
    return Isolate.run(() async {
      final argon2 = Argon2id(
        parallelism: _argonParallelism,
        memory: _argonMemoryKiB,
        iterations: _argonIterations,
        hashLength: 32,
      );
      final key = await argon2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      return key.extractBytes();
    });
  }

  static Uint8List _randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }
}

class _Parsed {
  final bool hasPassword;
  final Uint8List? salt;
  final Uint8List aad;
  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;

  const _Parsed({
    required this.hasPassword,
    required this.salt,
    required this.aad,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });
}
