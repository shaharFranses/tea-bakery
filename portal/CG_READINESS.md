# tea-bakery (working name; final title TBD): CrazyGames readiness sheet

> Title note (2026-10-25): 'Tea & Tarts' is being replaced because of Pop-Tarts risk. Growth is shortlisting names. The finalists get the same trademark and portal-name check before Shahar picks.
Prepared 2026-10-25 08:40 (Asia/Jerusalem) by TT Portal Ops. Research and writing only: no sign-in, no submission, no messages. **Portal Ops does not submit.** The account, Developer Terms and upload are Shahar's, with the TT Studio Manager.

**Sources and precedence.** Where FF's as-seen live form and the public docs disagree, **FF's as-seen form wins**, and the conflict is noted in §2.
- FF as-seen form (2026-10-24): `/home/box/portal-ops/games/flick-freight/submission/CRAZYGAMES_BASIC_SUBMISSION.md` ("AS SUBMITTED" section, which overrides FF's own earlier field list), `/home/box/portal-ops/portals/CG_BASIC_PLAYBOOK.md`, `/home/box/portal-ops/portals/REQUIREMENTS.md`
- Public docs (fetched 2026-10-25): https://docs.crazygames.com/requirements/intro/ · /technical/ · /gameplay/ · /ads/ · /quality/ · /game-covers/ · https://docs.crazygames.com/sdk/intro/ · /sdk/game/ · /sdk/video-ads/ · https://docs.crazygames.com/resources/basic-launch-metrics/ · https://docs.crazygames.com/faq/
- Box: SD checklist `/workspace/pipeline-ops/spike/sd/PORTAL_CHECKLIST.md`, Growth lever sheet `/cursor/stores/store-b2e48cc4-…/growth/portal-lever-sheet.md`, my `cg-requirements.md` and `trademark-check.md` (same folder), Growth `/workspace/audience/game4-themes.md`
- Repo facts: `/workspace/tea-and-tarts` (starter clone, **no commits yet**). `project.godot` sets a 390×844 portrait base (`handheld/orientation=1`), canvas_items/expand, Compatibility renderer. The PKD studio intro is 1.93 s and skippable.

Status legend: ✅ done · 🟡 in progress / partly · ⬜ not started · ❓ open / unverified · 👤 Shahar's decision

---

## 1. Top items for tea-bakery (what's specific to this game vs FF's playbook)
1. **Portrait game on a landscape desktop iframe.** FF was also portrait. CG requires the game to be playable in landscape on desktop, with portrait games shown with "black bars or background images" on the sides (technical page). The game's 390×844 base needs a **themed tea-room side background**, not plain bars, on the 16:9 iframe sizes, and the board must stay readable at 800×450 and 821×462 at DPR 1.
2. **Tags: plan, checked against the public tag list.** All four planned tags exist as CG tags: `logic`, `relaxing`, `food`, `cooking` (all present among 215 tag slugs on https://www.crazygames.com/tags, fetched 2026-10-25). Two caveats: the form's tag picker list is ❓ unconfirmed (FF only proves Skill/Physics/Collect/Speed/2D exist there), and **`cooking` is a risky tag** (see §5).
3. **Pop-Tarts guardrails apply to every asset** (covers, previews, description): no rectangular frosted toaster pastries with sprinkles, no "pop" wordplay, no lookalike logo. Kellogg now has pending POP-TARTS filings for browser games (IC 41) and puzzles (IC 28). See `trademark-check.md`. Portal searches for "tarts" also surface a "Mini Pop Tarts" cooking game, so our art must read clearly as *tea-room pastries*, not toaster pastries.
4. **Not "targeted at kids".** That's a CG QA rejection reason (FAQ). The audience is adult women 35+ (Growth), so covers and copy should look grown-up and cozy, not preschool. Keep all "tarts" wording plainly about pastry, to stay PEGI-12 safe.
5. **Size: same 36 MB problem as FF.** The stock template gives about 36.2 MB unzipped (starter CI f0fef91; wasm 35.4 MB). FF shipped 36.0 MB unzipped / 8.3 MB zipped. A PKD **slim 2D template** is being built (`/workspace/pipeline-ops/engine/build_slim.log`, still being written at 08:31). If it lands, tea-bakery may be the first PKD game under the 20 MB mobile-homepage ideal.
6. **Time to first board.** The PKD intro (1.93 s, skippable) plus the Godot boot come before gameplay. Basic has no 1-click rule, but Basic KPIs reward fast conversion (≥80% playing 1+ min, load <10 s; basic-launch-metrics). Full Launch requires landing in gameplay with at most 1 click. **Design rule now:** first launch goes straight to board 1 with the tutorial inside it, with no title screen or recipe-book menu first.
7. **The SDK glue is already in the build.** Unlike FF (no SDK), the starter's `head_include.html` loads CG SDK v3 on crazygames.* hosts. Per the docs, once the SDK is present in Basic, **`gameplayStart` must fire when the board becomes playable**, and that event is where the initial download is measured. FF's "Basic form needs no SDK events" is true *for a build without the SDK*. Pick one: keep the glue with `gameplayStart` wired on board 1 (recommended; it also lets us confirm the measured size in the preview tool), or strip the glue for Basic.
8. **AI-tools disclosure.** It's a form field (FF disclosed Grok and Cursor). The art is made with in-house Python tools (`art/tools/ttdraw.py` etc.). Whatever AI tools touch code, art, copy or covers must be listed. Track this in `docs/art/LICENSES.md`.

## 2. Docs vs FF's as-seen form: conflicts (FF wins)
| Topic | Public docs say | FF as-seen form (2026-10-24) | Use |
|---|---|---|---|
| SDK events for Basic | SDK optional; *if integrated*, `gameplayStart` required (technical) | Form asks for no SDK events; FF shipped with no SDK | No form field. But if our SDK glue ships, wire `gameplayStart` (§1.7) |
| Description | "description and controls" (intro); FAQ: "description, instructions, thumbnails" | **ONE Description field** (short + long merged) | Write one merged description |
| Category | Not documented | **No "Casual"**; FF used Arcade | **Puzzle** (a site category on crazygames.com). ❓ confirm on the form |
| Tags | Not documented | **Max 5** | 5 tags (§5) |
| Age rating | "Must be PEGI 12 compliant" | **PEGI 12 checkbox**, no separate age-rating field | Tick the checkbox; content stays PEGI-12-safe |
| AI disclosure | Not in docs | **AI-tools disclosure field** | List the tools used |
| Language / data collection / multiplayer | English required (gameplay page); privacy notice if collecting extra data | **Not on the form** | No fields, but the rules still apply (English in game; no extra data collection) |
| Preview videos | "mandatory" (game-covers page) | FF: "optional for Basic but recommended" | Treat as optional for Basic, but **make them anyway** (they drive homepage CTR) |
| Cover format | Sizes only, no format | PNG worked | PNG |
| SD checklist short/long split, tag list, "Casual" | `PORTAL_CHECKLIST.md` drafted short + long description and 9 tags | Superseded by the form | Follow FF |

## 3. SDK requirements: Basic vs Full
| Item | Basic Launch | Full Launch | tea-bakery status |
|---|---|---|---|
| SDK | Optional (ads off; `adsDisabledBasicLaunch`) | Mandatory | 🟡 SDK v3 glue in `html/head_include.html` (from the starter) |
| `gameplayStart` | Required only if the SDK is present; the first call sets measured initial size | On every start/resume/next board | ⬜ wire on first playable board (not on the intro or menu) |
| `gameplayStop` | — | On every break (menu, board solved, recipe-book screen); not on tab blur | ⬜ |
| `loadingStart/Stop` | Optional ("not required for Godot") | Optional | ✅ in glue |
| `happytime()` | Optional | Optional, sparingly (e.g. a chapter / recipe card completed, not every board) | ⬜ decide |
| `muteAudio` setting + listener | — | **Required** for HTML5/Unity/Cocos/Construct; overrides the in-game sound toggle | ❌ not in starter |
| Midgame ads | Off | Only at natural breaks (between boards), never on nav buttons; pause and mute on `adStarted`; SDK caps at ~1 per 3 min | 🟡 starter `Ads` adapter; placement design ⬜ |
| Rewarded ads | Off. **No dead rewarded buttons** | Optional, video icon, equal-size "no thanks", non-ad alternative (e.g. a hint bought with stars), never reward on `adError`, not on an active board | ⬜ (likely "watch for a hint") |
| AdBlock | — | Game fully playable with AdBlock | 🟡 starter hides rewarded until adblock is known |
| Data module | — | Progress save, if applicable | 🟡 starter `Store` writes CG data + localStorage |
| 1-click to gameplay | — (KPI pressure only) | **Required (max 1 click)** | ⬜ design rule §1.6 |
| Integration route | HTML5 v3 glue (current) **or** the official Godot 4 addon (`res://addons/crazygames`, `await CrazyGames.is_initialised_async()`, `CrazyGames.Game.gameplay_start()`) | same | ❓ **addon v2.0.0 (2026-10-21) compatibility with Godot 4.3 is unconfirmed**; stay on the HTML5 glue unless tested |

## 4. Build size guidance
| Limit (docs) | Value | tea-bakery now |
|---|---|---|
| Initial download | ≤50 MB (with SDK: measured up to the first `gameplayStart`; without SDK: total size) | ~36.2 MB stock (starter CI f0fef91): ✅ pass |
| Mobile homepage eligibility | **≤20 MB** initial | ❌ 36.2 MB stock. Hope: the PKD slim 2D template (in progress) |
| Basic KPI guidance | build <20 MB, load <10 s, conversion ≥80% | ❓ unmeasured |
| Total size | ≤250 MB (≤50 MB without SDK) | ✅ |
| File count | ≤1500 | ✅ ~8 files (FF: 8) |
| Paths | relative only | ✅ starter |
| Zip | index.html at root, no .gz duplicates/dotfiles | ✅ `tools/cg_zip.sh` → `dist/<game>-cg-<sha>.zip` + md5 + listing |
Levers: the slim template (2D-only, stripped modules), keeping the .pck small (compress textures as WebP, ogg audio), wasm-opt, Brotli/gzip, and lazy-loading later chapter packs only if needed. Re-measure in the CG preview tool, which shows the measured initial size.

## 5. Tags and category
- **Category:** Puzzle (❓ confirm on the form; "Casual" doesn't exist).
- **Planned tags:** logic, relaxing, food, cooking. All exist on the public tag list (2026-10-25). Growth's counts: `food` 112, `cooking` 55 (game4-themes.md §1b).
- **Recommended 5 (max):** **Logic · Relaxing · Food · Brain · 2D**
  - Why not `cooking` first: on CG, `cooking` means Papa's-style time-management games, and Growth found every CG bakery game is a sim or time-management game. The quality guidelines want the name and imagery to "reflect accurately the type of game". A cooking tag could pull the wrong players and hurt the ≥80% conversion KPI. Keep `food` for the theme and use `brain` for the puzzle audience.
  - Alternates: `cooking` (if Shahar wants the extra discovery; swap out `2D`), `daily` (if a daily "Bake of the Day" board ships), `easy`, `cute`.
  - ❓ Whether `brain` and `2D` appear in the form's picker: `2D` is confirmed by FF; `brain` is only on the public tag list.

## 6. Required assets (stamp every asset with its build commit, per FF)
| Asset | Spec | Status |
|---|---|---|
| Cover 16:9 | 1920×1080 PNG | ⬜ |
| Cover 2:3 | 800×1200 PNG | ⬜ |
| Cover 1:1 | 800×800 PNG | ⬜ |
| Cover rules | Consistent art across all 3; title is the only text (no "New"/"Play"); no borders, icons or store logos; no blurry or unlicensed art; not a bare screenshot; **must match the current in-game art** (FF had to redo covers on submit day). **T&T:** no Pop-Tarts-like pastries, adult cozy look, inland tea room (no sea/harbour, so it stays distinct from Sudoku Dash) | ⬜ |
| Preview 16:9 | 1920×1080, 15–20 s (FF: 16.1 s), silent (no audio stream), H.264 + faststart, ≤50 MB, opens on the static cover frame; no black intro, black bars, cursor, promo text or app icons; no speed-up | ⬜ (optional for Basic per FF; recommended) |
| Preview 2:3 | 1080×1620, same rules | ⬜ |
| Asset stamp | Filenames or a sidecar note with the build commit, e.g. `cover-landscape-1920x1080_<sha>.png` | ⬜ |
| Licence ledger | `docs/art/LICENSES.md` row for every shipped third-party file + AI-tool notes | 🟡 starter rows only |

## 7. Metadata fields (as FF saw the form)
| Field | tea-bakery value (draft) | Status |
|---|---|---|
| Game name | TBD (Growth shortlist, then trademark check, then Shahar picks). ❓ Check whether the form allows a colon/subtitle | 🔴 |
| Game files | `dist/tea-bakery-cg-<sha>.zip` + md5 (from the QA-passed gated build) | ⬜ |
| Description (ONE field) | Merged hook + rules + features. Rules line: "Place one pastry in every row, every column and every colour patch of dough, and no two pastries may touch, not even diagonally." No other-portal or app-store links, no other PKD games | ⬜ |
| Controls | Tap/click a cell to place a pastry; tap again to mark/clear (❓ match final bindings); keyboard if supported. Avoid Esc and Ctrl+W bindings | ⬜ |
| Category | Puzzle | 🟡 |
| Tags (≤5) | Logic, Relaxing, Food, Brain, 2D | 🟡 |
| Orientation / mobile | Portrait; mobile yes (touch) | 🟡 |
| Covers ×3, previews ×2 | §6 | ⬜ |
| AI-tools disclosure | List of tools actually used (e.g. Grok, Cursor; plus any image or copy tools) | ⬜ |
| PEGI 12 checkbox | Tick (content is PEGI-3-safe) | ⬜ |
| Not on the form (per FF) | language, data collection, multiplayer, separate age rating | — |

## 8. Content rules checklist
| Rule (source) | T&T note | Status |
|---|---|---|
| PEGI 12 compliant; not kids-targeted (gameplay, FAQ) | Adult cozy art; "tarts" only in the pastry sense | ⬜ |
| English (gameplay) | EN only at launch | ✅ plan |
| Originality; not easily confused with another game (gameplay, quality) | Distinct from Bakedoku (iOS) and Cuppadoku; avoid Pop-Tarts trade dress | 🟡 |
| No cross-promotion (gameplay) | No links or buttons to Sudoku Dash, Flick Freight, GitHub Pages or other portals; the studio intro is fine as branding, with no link | ⬜ verify in build |
| No custom fullscreen button (gameplay) | — | ⬜ verify |
| Readable at DPR 1 at 907×510, 1216×684, 1077×606, 821×462, 1366×768, 1920×1080, 1536×864, 1280×720, 800×450, 1080×607 (gameplay) | The starter QA matrix covers only 800×450/821×462/907×510. Add the rest; portrait board plus side background | ⬜ |
| Mouse + keyboard + touch; Chrome/Edge; Safari; 4 GB Chromebook (technical) | — | ⬜ |
| `user-select:none`, safe areas, iOS AudioContext resume on touch (technical) | ✅ in starter glue | ✅ |
| Basic: works with ads disabled; no dead rewarded buttons (ads) | Starter hides rewarded when unavailable | 🟡 verify |
| Privacy notice only if extra data is collected (technical) | None planned | ✅ |
| Trademark guardrails (`trademark-check.md` §5) | No toaster-pastry look, no "pop" | ⬜ |

## 9. Step-by-step submission (with status)
| # | Step | Owner | Status |
|---|---|---|---|
| 1 | Create the CG developer account early (empty is fine) to **see the live form**, per FF | 👤 Shahar (+TT SM) | ⬜ (FF's account already exists; ❓ whether T&T reuses the same studio account) |
| 2 | Decide on the Developer Terms (https://files.crazygames.com/documents/developer_terms_20250818.pdf) and whether to opt into exclusivity at Full Launch (+50% for 2 months; affects Poki/GD timing; lever sheet) | 👤 Shahar | ⬜ |
| 3 | Confirm the form's category list, the tag picker list (`logic`, `relaxing`, `food`, `brain`, `2D`, `cooking`), and whether the game name can include the subtitle | TT SM with Shahar, logged in | ❓ |
| 4 | Decide whether the SDK glue ships in Basic (keep and wire `gameplayStart`, or strip) | TT SM / Godot dev | ⬜ |
| 5 | Build: first commit; slim template if ready; `ci/run.sh` PASS; `ci/run.sh --gate` → gated dir + `dist/…-cg-<sha>.zip` + md5 | Godot dev / CI | ⬜ (repo has no commits) |
| 6 | QA PASS on the gated build, including the full CG iframe-size matrix, portrait-on-landscape side background, Safari/iOS, and ads-disabled behaviour | QA | ⬜ |
| 7 | Covers ×3 + previews ×2 cut **from the gated commit**, stamped with the sha; the Pop-Tarts guardrail review | Art / PO | ⬜ |
| 8 | Field sheet filled from §7 (one description, controls, category, 5 tags, orientation, AI disclosure, PEGI 12) against the gated sha | Portal Ops (draft) | 🟡 drafts here |
| 9 | Upload the zip to the CG **preview tool**; confirm it boots, `gameplayStart` fires (if the SDK ships; note the environment may read `local`/`disabled` in preview), and check the measured initial size | TT SM with Shahar | ⬜ |
| 10 | Final cross-check: zip md5, covers and previews all match the same sha | Portal Ops | ⬜ |
| 11 | Submit for Basic Launch | 👤 Shahar (+TT SM). **Not Portal Ops** | ⬜ |
| 12 | Record the AS-SUBMITTED values (game id, build id, category, tags, AI tools) in a T&T submission sheet; update CURRENT_BUILD.md Portal | Portal Ops | ⬜ |
| 13 | Basic KPI window (≥7 days AND ≥500 plays, or 21 days max): watch avg playtime (10+ min), D1 (10–15%), conversion (80%+); updates go live instantly | Growth / TT SM | ⬜ |
| 14 | If invited to Full: `muteAudio`, `gameplayStop`, ad placements, 1-click landing, AdBlock check, then Full QA | Godot dev / QA | ⬜ |

## 10. Open items
1. ❓ **CG form tag picker and category list** are not confirmed for tea-bakery (only the public tag list was checked). Is `brain` selectable? Is "Puzzle" a form category?
2. ❓ **Godot 4.3 + official CrazySDK addon v2.0.0** compatibility is unverified (the store lists no version info, and 2025 reviews report errors). Staying on the HTML5 v3 glue avoids the question.
3. ❓ **Slim 2D engine template**: still building (`build_slim.log`). Until it lands, T&T is ~36 MB, over the 20 MB mobile-homepage ideal.
4. ❓ Final title TBD. Also check whether the game name field accepts a colon/subtitle and what length it allows.
5. ❓ Preview videos: docs say mandatory, FF says optional for Basic. Make them anyway.
6. 👤 SDK in Basic (keep/strip), the Developer Terms, exclusivity, and account reuse.
7. ⬜ `muteAudio` handling is missing from the starter (Full Launch requirement).
8. ⬜ FF's review outcome is still pending (CG_BASIC_PLAYBOOK "Rejections: none yet"). Re-read it before T&T submits, for any rejection lessons.
9. ⬜ PLAYBOOK stage 6 references a "field sheet" template that doesn't exist on the box. §7 here can serve as T&T's.
