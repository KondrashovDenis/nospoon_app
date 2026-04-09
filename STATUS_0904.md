# 🥄 NO SPOON MESSENGER — STATUS_0904.md

*Сессия: апрель 2026 · claude.ai (claude-sonnet-4-6)*

---

## Где мы сейчас

**Текущая версия приложения:** v2.1.1  
**Репо app:** github.com/KondrashovDenis/nospoon_app  
**Репо python:** github.com/KondrashovDenis/nospoon  
**Домен:** nospoon.ru (куплен, не задеплоен)  
**Relay:** spoon-messenger-relay.nonospoon.workers.dev  

---

## Что сделано в этой сессии

### Лендинг nospoon.ru — `index.html`

Статический одностраничный сайт. Один файл, без зависимостей кроме Google Fonts (VT323).

**Секции:**
- Hero — слоган, badges, CTA кнопки
- How it works — 5 шагов, pipeline `text → brainfuck → spoon → .bin → ipfs → relay`
- Features — 6 карточек в сетке
- Live Demo — JS-порт BF-компилятора, работает в браузере без сервера
- Network Status — дашборд с seed-значениями + fetch к relay
- Philosophy — манифест с подсветкой при скролле
- Download — 4 карточки (APK / source / python cli / iOS)
- Footer

**Технические детали:**
- Matrix rain из символов BF/Spoon (`+ - > < [ ] . ,`) на canvas
- Scanlines overlay через CSS `repeating-linear-gradient`
- Screen flicker анимация на hero-заголовке
- Cursor blink — мигающий прямоугольник как на CRT
- Manifesto scroll highlight — строки зажигаются при прокрутке
- Все звуки/эффекты — чисто CSS/JS, без внешних ресурсов кроме шрифта

**EN/RU переключатель:**
- Кнопки EN / RU в навбаре
- Атрибуты `data-en` / `data-ru` на каждом текстовом узле
- Покрыто: nav-ссылки, все заголовки, описания, кнопки, placeholder textarea, статус relay, footer
- Переключение мгновенное, без перезагрузки

**Кнопка скачать (APK):**
- Открывает модальное окно в терминальном стиле
- Активные ссылки: GitHub app repo, GitHub Python CLI
- Заглушки: Google Play, TestFlight (opacity 0.36, pointer-events none)
- Закрытие: кнопка X, клик по оверлею, Escape
- Когда выйдет APK — заменить ссылку в `.ml` на прямую ссылку releases

**Дашборд сети:**
- Seed-значения: Downloads=27, Boards=54, Messages=108
- Count-up анимация при загрузке (0 → seed за ~1.5 сек)
- Fetch к `RELAY/stats` с таймаутом 6 сек
- Если relay отвечает: seed + данные из relay (boards, messages)
- Если нет (CORS / offline): остаются seed-значения, статус dim

**JS BF-компилятор (demo секция):**
- Полный порт алгоритма из `core/compiler.py`
- UTF-8 побайтово (кириллица = 2 байта, каждый отдельно)
- Множители через `Math.round(Math.sqrt(ascii))` как в Python
- Spoon bit-stream из prefix-кодов
- Статистика: chars / bf ops / spoon bits / bin bytes
- Анимация вывода посимвольно с цветом по типу команды
- Ctrl+Enter запускает компиляцию

---

## Куда класть файл на сервере

```
/var/www/nospoon.ru/
└── index.html          ← единственный файл
```

Nginx конфиг (минимальный):
```nginx
server {
    listen 80;
    server_name nospoon.ru www.nospoon.ru;
    root /var/www/nospoon.ru;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```
SSL через Caddy или certbot — стандартно.

---

## Что нужно сделать после деплоя

### 1. CORS на relay (приоритет)
Если дашборд показывает `relay · no live data` — Cloudflare Worker не отдаёт `Access-Control-Allow-Origin: *`.

Добавить в `worker.js`:
```javascript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

// В обработчике OPTIONS:
if (request.method === 'OPTIONS') {
  return new Response(null, { headers: corsHeaders });
}

// К каждому Response добавлять:
return new Response(body, { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
```

### 2. Endpoint /stats на relay
Дашборд делает `GET /stats` и ожидает JSON:
```json
{ "boards": 12, "messages": 47 }
```

Добавить в `worker.js`:
```javascript
if (url.pathname === '/stats') {
  const keys = await kv.list();
  const boards = keys.keys.length;
  // messages — сумма длин всех списков CID
  return new Response(JSON.stringify({ boards, messages: 0 }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}
```

### 3. Заменить заглушку APK
В `index.html` найти строку:
```html
<a class="ml" href="https://github.com/KondrashovDenis/nospoon_app" ...>[ WATCH REPO → GITHUB ]</a>
```
Заменить href на прямую ссылку releases когда выйдет Release APK.

---

## Приоритеты разработки (следующие сессии)

| Приоритет | Задача | Версия |
|-----------|--------|--------|
| 1 | Release APK — убрать debug символы, уменьшить размер | v2.2.0 |
| 2 | /stats endpoint в worker.js + CORS | — |
| 3 | Onboarding экран при первом запуске | v2.3.0 |
| 4 | Иконка приложения (ложка в терминальном стиле) | v2.3.0 |
| 5 | Push уведомления / фоновый polling 60 сек | v2.4.0 |
| 6 | TestFlight для iOS | v2.5.0 |

---

## Открытые вопросы

- Нужен ли `/stats` с реальным подсчётом messages или достаточно seed?
- CORS на relay — проверить после деплоя лендинга
- Ook! как дополнительный слой в церемонии — реализовывать?
- Whitespace стеганография — оставить как идею?
- Bluetooth/WiFi Direct оффлайн — приоритет?

---

## Технический стек проекта (справка)

| Слой | Технология |
|------|-----------|
| Mobile app | Flutter 3.27.4 / Dart |
| Codec | Brainfuck → Spoon (prefix code) |
| Storage | IPFS via Pinata v2 API |
| Relay | Cloudflare Workers + KV |
| Sound | flutter_soloud (синтез, без mp3) |
| Landing | Static HTML/CSS/JS, VT323 font |
| Python proto | github.com/KondrashovDenis/nospoon |

---

*🥄 there is no spoon.*  
*Документ создан: апрель 2026*
