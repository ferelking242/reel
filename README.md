# Watchtower Real

TikTok-style feed UI for **[Watchtower](https://github.com/ferelking242/watchtower)**.

> **UI-only repo.** The server, extensions, database, and all backend logic are in [ferelking242/watchtower](https://github.com/ferelking242/watchtower).

---

## Structure

```
watchtower-real/
└── app/
    └── watchtower-real/   ← Flutter app (TikTok feed UI)
        └── lib/
            ├── features/feed/     ← Vertical feed player
            ├── remote/            ← HTTP client → watchtower API
            ├── core/              ← Theme, config
            └── router/            ← Navigation
```

## How it fits

```
watchtower-real (this repo)         watchtower (main repo)
─────────────────────────           ───────────────────────────────
  TikTok feed UI          ──HTTP──▶  Embedded server (port 4567)
                                      OR
                                     Headless server (port 8080)
                                      │
                                     Extensions (JS/Dart)
                                     Database (Isar)
                                     Cache / Prefs
                                     Rust / Go
```

## Download

| Platform | Link |
|---|---|
| **Android APK** | [Actions → build-apk](https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml) |
| **iOS IPA** (TrollStore) | [Actions → build-ipa](https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml) |

## Build locally

```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower-real
flutter pub get
flutter run
```

## Roadmap

- [x] Vertical feed (PageView)
- [x] Connect to watchtower remote API
- [x] Video player (media_kit)
- [ ] Infinite scroll + prefetch
- [ ] Merge into `watchtower` as `lib/modules/feed/`

## Server / Backend

Everything backend → **[ferelking242/watchtower](https://github.com/ferelking242/watchtower)**
