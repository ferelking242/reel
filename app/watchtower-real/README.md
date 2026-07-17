# Watchtower Real

TikTok-style vertical feed UI for **[Watchtower](https://github.com/ferelking242/watchtower)**.

> **This is UI-only.** The server, extensions, database, and all backend logic live in the main [watchtower](https://github.com/ferelking242/watchtower) repo.  
> `watchtower-real` is developed separately for fast iteration and will be merged into `watchtower` once validated.

---

## What this is

A lightweight Flutter app that displays content from a running Watchtower instance in a TikTok-style vertical feed. No embedded JS engine, no Rust, no Go — just UI + HTTP.

## What this is NOT

- ❌ The server (→ `watchtower/server/`)
- ❌ The extension engine (→ `watchtower/lib/eval/`)
- ❌ The database (→ `watchtower` uses Isar)
- ❌ The torrent client (→ `watchtower/go/`)

## How it connects

```
watchtower-real UI
       │  HTTP (REST API)
       ▼
watchtower embedded server  (port 4567 on device)
       OR
watchtower headless server  (port 8080 on cloud)
```

## Same tech stack as watchtower

`watchtower-real` uses the exact same packages as `watchtower` so the merge is seamless:

| Package | Version |
|---|---|
| `flutter_riverpod` | `^3.1.0` |
| `isar_community` | `^3.3.2` |
| `media_kit` | git (kodjodevf fork) |
| `flex_color_scheme` | `^8.3.1` |
| `go_router` | `^17.2.0` |

## Merge into watchtower

At build time, a GitHub Actions workflow copies the `lib/modules/feed/` module from `watchtower-real` into `watchtower/lib/modules/feed/`.  
When running inside watchtower:
- No separate DB — uses watchtower's Isar instance directly
- No separate cache — uses watchtower's existing HTTP cache
- No separate prefs — uses watchtower's Hive boxes

## Build

```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower-real
flutter pub get
flutter run
```

CI builds the APK + IPA automatically on every push to `main`.
