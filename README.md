# no spoon messenger

> there is no spoon.

Anonymous messenger with esoteric encoding. Messages are compiled to Brainfuck, encoded into Spoon prefix code, stored on IPFS, and delivered through a Cloudflare Workers relay.

No accounts. No identity. No server-side history. Only the message.

**Website:** [nospoon.ru](https://nospoon.ru)

## Pipeline

```
text → brainfuck → spoon → .bin → ipfs → relay → ipfs → spoon → brainfuck → text
```

## Features

- **No registration** — boards are identified by random 16-char keys
- **Brainfuck codec** — text compiled to BF with optimal factorization
- **Spoon encoding** — prefix code packing for compact binary
- **TTL** — messages expire automatically (1h / 6h / 24h / 7d)
- **Password protection** — optional per-message encryption
- **IPFS storage** — content-addressed via Pinata
- **CRT aesthetics** — phosphor green terminal, scanlines, blinking cursor, modem sounds
- **Offline-first codec** — encoding works without network

## Downloads

- [Android APK](https://github.com/KondrashovDenis/nospoon_app/releases/latest) — direct install
- [Windows](https://github.com/KondrashovDenis/nospoon_app/releases/latest) — portable, no installer

## Tech stack

- **Framework:** Flutter / Dart
- **Codec:** Brainfuck compiler + Spoon prefix code
- **Storage:** IPFS via Pinata v2 API
- **Relay:** Cloudflare Workers + KV
- **Sound:** flutter_soloud (synthesized, no audio files)
- **Notifications:** flutter_local_notifications + workmanager (Android)

## Related

- [nospoon](https://github.com/KondrashovDenis/nospoon) — reference Python implementation of the Spoon codec

## License

MIT

---

🥄 *there is no spoon.*
