# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Roblox game (brainrot digging/collecting) written in Luau, synced into Studio with Rojo. The repo holds **only code** (`src/`); the map/Workspace lives in Team Create and Rojo never touches it. Code, comments, identifiers and commit messages are in Turkish written without diacritics (ASCII) — keep that style.

Two people develop on the same place: only ONE person may be connected to Rojo at a time, otherwise the last connection overwrites the other's code.

## Commit and push after every change

After each finished change, without asking:

1. Run `lune run tools/check.luau`. If it fails, fix the error or stop and report it. Do not commit broken code.
2. Stage only the files you changed (not `git add -A`: the user may have unrelated edits from Studio).
3. Commit with a short Turkish ASCII message that says what changed (same style as `git log`).
4. `git push`. If rejected because the teammate pushed first, run `git pull --rebase`, then push again. On a rebase conflict, stop and report; do not force-push.

## Commands

Rojo and Lune live in `%LOCALAPPDATA%\Rojo\bin` (may not be on PATH — use the full path if needed). There is no build step, test runner, or linter beyond these Lune scripts:

- `lune run tools/check.luau` — compiles every `.luau` under `src/` to find syntax errors (does not execute). Run after edits.
- `lune run tools/api.luau` — finds `Module.func()` calls whose target field no longer exists in that module (catches renamed/deleted functions that would only fail at runtime).
- `lune run tools/fmt_test.luau` — the only unit-style test (for `src/shared/Format.luau`).
- Balance/tuning printers: `gelir.luau` (rarity income), `zorluk.luau` (rod × rarity bot simulation of the Stardew fishing minigame), `mutasyon.luau`, `kenar.luau`. These **duplicate constants** from `Rarity`/`Rods`/`DigMinigame`/`Mutations`/`Condition` because those modules use Roblox APIs (Color3 etc.) that Lune can't require — update them when the source values change.
- Place-file tools (take an `.rbxl` exported from Studio): `scan.luau` (backdoor scan), `senkron.luau` (diff Studio code vs disk), `fiyat.luau`, `konum.luau`, `inspect.luau`, `extract.luau` (place → src), `entegre.luau` (src → place), `cikar.luau` (extract objects to `.rbxm`).

The `.bat` files are the teammates' workflow (Windows): `KURULUM` (install), `BASLA` (pull + `rojo serve`), `YENILE` (pull while serving), `BITIR` (commit all + push, rebase on conflict), `KURTAR` (abort a stuck merge/rebase). `.bat` files must stay CRLF; `.luau/.json/.md` are LF (see `.gitattributes`).

## Architecture

Rojo mapping (`default.project.json`):

| Folder | Studio location |
|---|---|
| `src/server` (+ `Modules/`) | ServerScriptService |
| `src/client` | StarterPlayer > StarterPlayerScripts |
| `src/shared` | ReplicatedStorage > Shared |
| `src/replicatedfirst` | ReplicatedFirst (loading screen) |

File suffixes follow Rojo: `.server.luau` = Script, `.client.luau` = LocalScript, plain `.luau` = ModuleScript.

- **Networking** — `src/shared/Net.luau` is the single registry of all RemoteEvents (`Net.Events`, with direction comments per event). Server calls `Net.init()` (done in `Leaderstats.server.luau`, the earliest script) to create them under `ReplicatedStorage.Remotes`; both sides get them with `Net.event("Name")`. Adding a remote = add its name to `Net.Events`.
- **Player data** — `src/server/Modules/PlayerData.luau` is the single source of truth for persisted state (DataStore): currencies (`rot`, `rotCoins`), inventory of brainrots (`{uid, rarity, condition, mutation, name?, revealed, slot?, island?}`), tools, base slots, rewards, passes, etc. Server feature scripts go through it; new fields need defaults/migration there.
- **Shared config/catalog modules** in `src/shared` hold game data and tuning, used by both server and client: `Brainrots`, `Rarity`, `Condition`, `Mutations`, `Shovels`, `Rods`, `Detectors`, `Bases`, `Canta` (bag capacity/upgrade prices), `Passler`/`RobuxMagaza` (Robux products), `OyunConfig` (hand-tuned values, NPC names), `Assets` (asset IDs + naming conventions for models dropped into `ReplicatedStorage > Assets` — code falls back to generated visuals when a model is missing).
- **Server scripts** are feature-oriented (`KaziSistemi` dig system, `BaseSistemi` base/slots/income, `Detective`, `Fuse`, `Olta` fishing, shops, `AdminPanel`, …). Cross-script server communication uses BindableEvents created by one script and found via `script.Parent:WaitForChild("<Script>"):WaitForChild("<Event>")` (e.g. `BaseSistemi.BaseYenile`, `KaziSistemi.KurekYenile`).
- **Client** — UI is built in code (`UI.luau` helpers, `Menuler.client.luau` holds most menus); client scripts mirror server features and talk only via `Net` remotes.

### Systems (server side; config usually in the same-named `src/shared` module)

- Dig (GPS spots + minigame): `src/server/KaziSistemi.server.luau`
- Detective (reveals black brainrots): `src/server/Detective.server.luau`
- Base / slots / passive income: `src/server/BaseSistemi.server.luau`
- Brainrot seller NPC: `src/server/Satici.server.luau`
- Inventory / bag upgrade: `src/server/Modules/Envanter.luau`, `src/shared/Canta.luau`
- Shovel shop: `src/server/Magaza.server.luau`
- Island shovel/pickaxe sellers: `src/server/AdaSaticilari.server.luau`
- Rods / fishing: `src/server/Olta.server.luau`, `src/server/Modules/Olta.luau`
- Flyboard: `src/server/Flyboard.server.luau`
- Speed upgrade: `src/server/Hiz.server.luau`
- Level / XP: `src/server/Modules/Seviye.luau`
- Fuse machine: `src/server/Fuse.server.luau`
- Lucky Block + block rain: `src/server/Modules/LuckyBlockOdul.luau`
- Egg Gacha (Gacha NPC, 500 Robux product, egg spin): `src/server/Modules/Gacha.luau`, `src/client/Gacha.client.luau`, config `src/shared/Gacha.luau`
- AFK luck (clover fields in `Workspace.CloverAreas`, Luck Points, Leprechaun field upgrades): `src/server/Modules/AfkSans.luau`, `src/client/AfkSans.client.luau`, config `src/shared/AfkSans.luau`
- Quests: `src/server/Gorev.server.luau`
- Daily reward: `src/server/Modules/Odul.luau`
- Playtime / social rewards: `src/server/SosyalOdul.server.luau`
- Friends buff: `src/server/Modules/Arkadaslar.luau`
- Index (discovery book): `src/server/Index.server.luau`
- Island teleport: `src/server/AdaTeleport.server.luau`
- Rot Coin shop: `src/server/RotCoinMagaza.server.luau`
- Robux store: `src/server/RobuxMagaza.server.luau`
- Game Passes: `src/server/Passler.server.luau`
- Settings: `src/server/Ayarlar.server.luau`
- Admin panel: `src/server/AdminPanel.server.luau`
- Tutorial: `src/server/Modules/Ogretici.luau`
- Back items display: `src/server/SirtEsyalari.server.luau`
- Studio error relay: `src/server/HataIletici.server.luau`

Numbers (chances, prices, durations) come from the `src/shared` modules, not from script comments. Header comments in server scripts can be stale (e.g. `Fuse.server.luau` still lists old fuse chances; real values are in `src/shared/Fuse.luau`).

Core loop: GPS shows nearby dig spots → client requests dig (`SuzmeKaz`) → minigame (`DigMinigame`/`KaziMinigame`) → brainrot arrives black/unrevealed in inventory → Detective reveals its name → place it on base slots for passive `rot` income.

- Scriptleri SADECE klasördeki dosyalardan düzenle. Studio MCP'yi sadece okumak ve konsola bakmak için kullan.

Kurallar:
- Bu proje Rojo kullanıyor. Scriptleri SADECE klasördeki dosyalardan düzenle, asla Studio içinden düzenleme.
- Studio MCP'yi sadece hiyerarşiyi incelemek ve konsol hatalarını okumak için kullan.
- Tüm güvenlik ve doğrulama sunucuda yapılır, istemciden gelen veriye güvenme.
- Her sistem kendi ModuleScript'inde olsun.
- Kod yazdıktan sonra luau-lsp hatalarını kontrol et ve düzelt.
- Mevcut sistemlerin kısa bir listesini de ekle.
- Bana Türkçe cevap ver.
