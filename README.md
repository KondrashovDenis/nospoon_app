# no spoon messenger

> there is no spoon.

Anonymous messenger with esoteric encoding. Messages are compiled to Brainfuck, packed into Spoon prefix code, encrypted with the board key, and delivered through a Cloudflare Workers relay backed by IPFS.

No accounts. No identity. No server-side history. Only the message.

**Website:** [nospoon.ru](https://nospoon.ru)

## Pipeline

```
text → brainfuck → spoon → .bin → encrypt → relay → ipfs
                                                ↓
text ← brainfuck ← spoon ← .bin ← decrypt ← relay
```

## Features

- **No registration** — a board is a random 24-character key, shared by QR code
- **Brainfuck codec** — text compiled to BF with optimal factorization
- **Spoon encoding** — prefix code packing into a compact binary
- **End-to-end encryption** — XChaCha20-Poly1305 with a key derived from the board key; the relay stores only ciphertext and only knows a hash of the key
- **Password protection** — optional second layer, Argon2id mixed into the message key
- **Real TTL** — 1h / 6h / 24h / 7d; the expiry is authenticated inside the message, the relay forgets the entry and unpins the file from IPFS
- **No secrets in the app** — the storage key lives on the relay
- **CRT aesthetics** — phosphor green terminal, scanlines, blinking cursor, modem sounds

## What the encryption does and does not do

Spoon and Brainfuck are an encoding, not a cipher — anyone can decode a bare `.bin`. Protection comes from the envelope around it:

- Whoever has the **board key** can read and post on that board. Treat the key and its QR code as the secret.
- The relay operator, the storage provider, and anyone who learns a message CID see only ciphertext.
- The relay sees metadata: IP addresses, message sizes and timings, and which messages belong to the same board.
- Messages are not signed: all board members are equally trusted.
- Board keys are kept in the app's local storage on the device.

The crypto has not been independently audited.

## Downloads

- [Android APK](https://github.com/KondrashovDenis/nospoon_app/releases/latest) — direct install
- [Windows](https://github.com/KondrashovDenis/nospoon_app/releases/latest) — portable, no installer

Versions before 2.3.0 use the old protocol and no longer work.

## Tech stack

- **Framework:** Flutter / Dart
- **Codec:** Brainfuck compiler + Spoon prefix code
- **Crypto:** XChaCha20-Poly1305, Argon2id, HKDF-SHA256 (`cryptography_plus`)
- **Relay:** Cloudflare Workers + KV ([source](https://github.com/KondrashovDenis/nospoon/tree/main/cloudflare))
- **Storage:** IPFS via Pinata, behind the relay; if IPFS is unavailable the relay keeps the message itself until it expires
- **Sound:** flutter_soloud (synthesized, no audio files)
- **Notifications:** flutter_local_notifications + workmanager (Android)

## Development

```bash
flutter test                                                   # unit tests
flutter test test/integration --dart-define=E2E_RELAY=<url>    # end-to-end against a relay
flutter run --dart-define=RELAY_URL=http://127.0.0.1:8787      # against a local `wrangler dev`
```

## Related

- [nospoon](https://github.com/KondrashovDenis/nospoon) — relay source and the original Python prototype of the codec

## License

MIT

---

🥄 *there is no spoon.*
