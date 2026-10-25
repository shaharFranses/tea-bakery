# Tea & Tarts: CrazyGames requirements checklist (Godot 4.3 web)
Prepared 2026-10-25 (Asia/Jerusalem) from the official CrazyGames docs, all fetched 2026-10-25. Research only: no sign-in, nothing submitted.
Sources:
- [intro] https://docs.crazygames.com/requirements/intro/
- [tech] https://docs.crazygames.com/requirements/technical/
- [gp] https://docs.crazygames.com/requirements/gameplay/
- [ads] https://docs.crazygames.com/requirements/ads/
- [qual] https://docs.crazygames.com/requirements/quality/
- [cov] https://docs.crazygames.com/requirements/game-covers/
- [sdk] https://docs.crazygames.com/sdk/intro/
- [game] https://docs.crazygames.com/sdk/game/
- [vads] https://docs.crazygames.com/sdk/video-ads/
- [bl] https://docs.crazygames.com/resources/basic-launch-metrics/
- [faq] https://docs.crazygames.com/faq/
- [first] https://docs.crazygames.com/resources/getting-to-the-first-frame/
- [godot-store] https://store.godotengine.org/asset/crazygames/crazysdk/

## 0. Top items for a Godot build
1. **Size.** The initial download must be ≤50 MB. It must be **≤20 MB to be eligible for the mobile homepage**. Total size ≤250 MB, at most 1500 files [tech]. With the SDK integrated, the initial download is measured from the start of loading **until the first `gameplayStart`**. Without the SDK, the total size counts [tech]. The PKD starter currently builds a **36.2 MB release (stock wasm 35.4 MB)** (`pipeline-ops/starter/CURRENT_BUILD.md`, CI f0fef91). That passes the 50 MB limit but is well over 20 MB. The fix is a slim engine template (strip 3D and unused modules, optimize=size) plus wasm-opt, with Brotli/gzip and lazy `.pck` loading [first].
2. **SDK events.** Basic Launch needs only `gameplayStart` when the player reaches a playable state, and only if the SDK is present [tech]. Full Launch needs `gameplayStart`/`gameplayStop` on every pause, menu or level end [game]. `loadingStart`/`loadingStop` are optional and "not required for Godot" [game]. `happytime()` is optional and should be used sparingly, for real achievements only, not every level clear [game]. A Full Implementation must also honour the **`muteAudio` setting**, plus a settings-change listener for HTML5 [game].
3. **One click to gameplay.** For Full Launch, new users must land in gameplay immediately, with at most 1 click [gp]. A logic puzzle should drop a new player straight into level 1, with the tutorial built into that level [qual]. Don't put a title or menu screen in front of it.
4. **Ads in Basic Launch.** They are disabled (`adsDisabledBasicLaunch` error). The game must not freeze, and there must be no dead rewarded buttons [ads][vads].
5. **PEGI 12, English, and not aimed at kids.** "Content is targeted for kids" is listed as a QA rejection reason [faq]. A cozy bakery game needs art and copy aimed at teens and adults, not a preschool look.

## 1. Basic Launch vs Full Launch [intro][bl][faq]
| Area | Basic Launch | Full Launch (includes everything in Basic) |
|---|---|---|
| Technical | Initial download ≤50 MB; total ≤250 MB (50 MB without SDK); ≤1500 files | SDK integrated plus `gameplayStart` event |
| Gameplay | Basic visual QA; PEGI 12 | Full visual QA; **land directly in gameplay (max 1 click)** |
| Ads | CG monetization disabled; no external ads | Ads only through the SDK, following the guidelines; game works with AdBlock |
| Account | No external login | Progress linked to the CG account; CG username and avatar; auto-login (if applicable) |
| Multiplayer | n/a | n/a for this game |
| IAP | Not available | Invite only (Xsolla) |
| SDK | Optional | Mandatory |
- Basic is a soft launch to a small audience. It ends after **≥7 days live AND ≥500 plays**, or automatically at 21 days. KPI tracking is automatic and needs no SDK [bl]. Updates in Basic are auto-approved and go live instantly [bl][faq].
- Success guidance (not hard thresholds): 10+ min average playtime, 10–15% D1 retention, 80%+ conversion (≥1 min of play), load under 10 s, build under 20 MB [bl].
- After Basic: games with strong KPIs are invited to Full Implementation, followed by another QA review [faq].

## 2. SDK: what's required and how it's integrated
- **HTML5 v3:** `<script src="https://sdk.crazygames.com/crazygames-sdk-v3.js">` in the head, then `await window.CrazyGames.SDK.init()` before any call [sdk]. Environments are `local` (localhost/127.0.0.1 or `?useLocalSdk=true`), `crazygames`, and `disabled` (any other domain, where every call throws). Check `SDK.environment` before calling [sdk].
- **Official Godot 4 addon:** copy `crazysdk-godot-4` to `res://addons/crazygames`, enable the plugin, then `await CrazyGames.is_initialised_async()`. Main calls: `CrazyGames.Game.gameplay_start()` / `gameplay_stop()`, `CrazyGames.Game.happy_time()`, `await CrazyGames.Ad.request_ad_async("midgame"|"rewarded")`, `CrazyGames.has_adblock`, and signals `CrazyGamesBridge.callbacks.ad_started` / `ad_finished` / `ad_error`. Export with the "CrazyGames export preset" and test as `index.html` on localhost. `CrazyGamesBridge.get_environment()` returns `local`, `crazygames` or `disabled` [sdk][game][vads]. Godot Asset Store listing: v2.0.0, updated 2026-10-21, MIT, with 3 negative reviews from 2025 citing errors in older versions [godot-store].
- **Game module events** [game]:
  - `gameplayStart`: on game start, resume, revive, next level. **The first call sets the measured initial download size.**
  - `gameplayStop`: on every break (menu, level end, pause). Don't call it on tab blur; CG handles that.
  - `loadingStart` / `loadingStop`: optional. "Not required for Godot."
  - `happytime()`: sparingly, for big moments only (not every level complete).
  - `reportGameCompletedPercentage(0–100)`: new, HTML5-only for now (Godot marked not supported).
  - `setGameContext` / `clearGameContext`: attaches data (e.g. the level) to player feedback. HTML5 only.
  - `settings.muteAudio`: required for a Full Implementation on HTML5/Unity/Cocos/Construct. It must override the in-game sound toggle. `disableChat` doesn't apply to this game.
- **Video ads** [vads][ads]:
  - Call `requestAd("midgame"|"rewarded", {adStarted, adFinished, adError})`. Mute and pause on `adStarted` (not on request). Unmute and resume on finish or error.
  - Error codes: `adsDisabledBasicLaunch`, `unfilled`, `adblock`, `adCooldown`, `other`.
  - Midgame: only at natural breaks, never on a navigation button. The SDK caps midgames at about 1 every 3 minutes, so over-requesting is harmless.
  - Rewarded: clearly optional, with a video icon, and the "no thanks" option the same size and style. No chained ads. Offer a non-ad alternative (e.g. coins). Never reward on `adError`. Don't offer it on an active gameplay screen. Don't combine a midgame with a "rewarded continue" between the same two levels.
  - Banners: only on screens open for 5 s or more on average, never during gameplay, max 2 per screen.
  - AdBlock users must be able to play normally. Features may be gated, but only with a notice.
- **Data module:** use it for progress saves in a Full Implementation, if applicable. **User module:** account integration, if applicable [tech].

## 3. File size, file count and other technical rules [tech]
- Total ≤250 MB; **≤1500 files**; initial download ≤50 MB, or ≤20 MB for the mobile homepage. With externally hosted files, QA instead checks that gameplay is reached in ≤20 s.
- Use relative paths only.
- Must work in Chrome and Edge (games that misbehave in Safari get disabled there). Must run smoothly on a 4 GB Chromebook or it gets disabled on ChromeOS.
- Mouse, keyboard and touch (if mobile is supported). Must be playable in landscape on desktop. Orientations are set in the submission form, so don't build an orientation lock.
- Add `user-select:none` (with -webkit/-moz/-ms prefixes) on body. Handle safe areas in the CG app. Resume the iOS AudioContext on `touchend`.
- Sitelock, if used, must whitelist all CG domains and the app origins.
- A privacy/T&C notice is needed only if we collect data beyond the SDK events (e.g. adding analytics).
- Compressed builds only (Brotli/gzip) per [sdk]. That line sits in the Unity section; for Godot it's good practice [first].

## 4. Gameplay and quality rules [gp][qual]
- Readable at DPR 1 at these sizes: 907×510, 1216×684, 1077×606, 821×462, 1366×768, 1920×1080, 1536×864, 1280×720, 800×450 (mobile), 1080×607 (tablet).
- Consistent physics at 144/165 Hz. **English required.** If the game is localized, use the SDK `locale` and fall back to English.
- **No custom fullscreen button** (CG provides one).
- Original name and assets. Quality guideline: the name shouldn't be easily confused with another game, and generic names shouldn't be used ("Super Chess" is fine, "Chess" isn't).
- Controls: avoid Esc (exits fullscreen) and Ctrl/Cmd+W. Account for AZERTY keyboards.
- Full Launch: land new players in gameplay with at most 1 click. Guideline: onboarding happens inside gameplay, is skippable, and is visual-first.

## 5. PEGI / age rating [gp][faq]
- CG's audience is 13+, and games **must be PEGI 12 compliant**.
- Content targeted at kids is a rejection reason. Kids' games belong on CG's separate kids site, where monetization is disabled.
- Caution: "tarts" is also slang. Keep the copy unambiguous (bakery and pastry context only) so it stays clearly PEGI-safe.

## 6. No cross-promotion / external links [gp]
- No cross-promotion of external or internal games or platforms.
- Allowed exceptions, none of which may be a main-menu CTA:
  - privacy policy and T&C
  - community links (Discord, dev site) on the menu, provided they don't lead to a playable web version
  - Steam/Epic links (desktop only, main menu or end of a demo)
  - backlinks to CG home or category pages (not promoted)
  - links to games in the same series
- **App Store links are never allowed in-game.** Use the portal metadata fields instead.
- For PKD this means **no "More Pikeydi games" button** linking to other portals or our GitHub Pages builds. Links to Sudoku Dash etc. aren't "same series", so they aren't allowed.

## 7. Covers and preview video [cov]
| Asset | Spec |
|---|---|
| Landscape cover | 16:9, 1920×1080 (mandatory) |
| Portrait cover | 2:3, 800×1200 (mandatory) |
| Square cover | 1:1, 800×800 (mandatory) |
| Cover rules | Consistent art across all three; no borders; **the title is the only text** (no "New"/"Play"); no icons or store logos; no unlicensed or blurry art; not a bare screenshot |
| Preview video, landscape | 1080p, 16:9 (mandatory) |
| Preview video, portrait | 1080p, 2:3 (mandatory) |
| Video rules | 15–20 s (cut at 20 s); ≤50 MB; **no sound**; open on the static cover frame; no black screen or logo intro; no black bars; no default cursor; no "Play Now" or promo text; no app or social icons; no fast-forward (CG speeds it up itself); animation is fine if it isn't misleading |
- The docs don't specify an image file format (PNG/JPG) or a video container/codec. **Unverified**: it's set by the portal upload form, which needs a login.

## 8. Required metadata
- Docs: "qualitative metadata (game description and controls) and game covers (images and videos)" [intro]. The FAQ says "Game metadata (description, instructions, thumbnails)" [faq]. Supported orientations are set in the submission form [tech]. App-store links go in "configurable game metadata fields" [gp].
- **Unverified:** the exact developer-portal form fields (title or character limits, tags, category, short description, mobile/desktop toggles). developer.crazygames.com requires sign-in and wasn't accessed (per the brief). CG docs don't publish tag or category rules.
- Draft fields to prepare anyway (mirrors the Sudoku Dash checklist): title, short description, long description with feature bullets, controls (mouse/touch/keyboard), tags and category (Puzzle/Logic), orientations, covers ×3, videos ×2.

## 9. Pipeline Ops files on the box, and how they differ from the docs
Search: `rg -il 'crazygames|readiness|field sheet'` over /workspace, /home/box and /cursor/stores.
| File | What it is | Differences from current docs |
|---|---|---|
| `/workspace/pipeline-ops/spike/sd/PORTAL_CHECKLIST.md` (and an identical copy at `/workspace/sudoko_dash/PORTAL_CHECKLIST.md`) | Sudoku Dash CG **Basic Launch** checklist, 2026-10-20: assets, metadata draft, requirement-vs-build table | Mostly matches. **Missing:** (a) the official **Godot addon** route (it uses HTML5 v3 glue in head_include, which is still valid); (b) the **`muteAudio` setting** requirement for Full; (c) the "content targeted for kids" rejection reason; (d) "no custom fullscreen button"; (e) English-localization rule (it says "no requirement found", but the gameplay page requires English); (f) the new `reportGameCompletedPercentage`. It's per-game, not a reusable per-portal sheet. |
| `/cursor/stores/store-b2e48cc4-…/growth/portal-lever-sheet.md` | Growth "portal lever sheet" for CG, Poki and GD, with citations | Consistent with today's docs. It marks the Godot addon as unverified; it's now confirmed in [sdk] (Godot 4 steps) and [godot-store] (v2.0.0, 2026-10-21). Also says "Ads, banners and IAP are off" in Basic, which matches. |
| `/workspace/pipeline-ops/playbook/PLAYBOOK.md` | Pipeline playbook. Stage 6 "Portal kit" expects "covers, previews, copy, **field sheet**, CONTROLS.md" and the CG 800×450/821×462/907×510 QA matrix | References a "field sheet", but **no field sheet file exists** on the box (templates/ only has player-profile.md and spec.md). The QA matrix covers 3 of the 10 sizes CG lists. |
| `/workspace/pipeline-ops/starter/` (`html/head_include.html`, `autoload/ads.gd`, `tools/cg_zip.sh`, `qa/cg_sizes.py`) | PKD starter: HTML5 SDK v3 glue (gameplay start/stop, loadingStart/Stop, data save, adblock), audio gate on ad, user-select CSS, CG zip tool | Matches most rules. **Gaps vs docs:** no `muteAudio` / settings-listener handling (Full requirement); no `happytime`; release size 36.2 MB, over the 20 MB mobile-homepage limit. |
- **No dedicated "Pipeline Ops per-portal readiness checklist" or "field sheet" file exists.** The closest are the Sudoku Dash PORTAL_CHECKLIST.md and the growth lever sheet.

## 10. Not verified
- Developer-portal form fields, character limits, tags/category taxonomy, and cover/video file formats (login required).
- Whether the Godot addon v2.0.0 works cleanly on Godot **4.3** specifically: the docs give no version matrix and the store page shows "Version Info: None".
- Whether `loadingStart`/`loadingStop` are ignored or tolerated when called through the HTML5 glue from a Godot game (docs say only "not required for Godot").
