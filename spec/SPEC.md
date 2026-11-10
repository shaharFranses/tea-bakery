# tea-bakery (game #4, working name): spec v1.2, **LOCKED 2026-11-03** (v1.2 = one cake per chapter; v1.1 = structure: level map, 8 chapters × 12 levels = 96 levels, 1–3 stars per level; v1.0.2 = ch5 card rename, D-02 3 lines on phones, AC-53 note, art B2 approved)

**Title: TBD.** "Tea & Tarts" was dropped on 2026-10-25 (TT Studio Manager: Pop-Tarts trademark risk); Until Shahar chooses the title, this spec uses the working name **tea-bakery**, and the portal copy (§11) contains **no game name**. Theme and rules are unchanged. **No user-facing text may contain the old title (any spelling: "Tea & Tarts", "Tea and Tarts", …), the working name, LinkedIn, Meowdoku or "Pop-Tart"** (TT-AC-39). **The trademark concern applies to the game title, not to recipe names:** generic "tart(s)" in recipe/food names (e.g. the ch4 card "Jam tarts") is allowed (TT Studio Manager ruling, 2026-10-25).
**Build name placeholder (SM, 2026-10-25):** until Shahar picks the title, Godot `application/config/name` and the HTML page `<title>` are the neutral **"Bakery Logic Puzzle"**. It is a descriptive placeholder, not a game name: it matches no `banned_user_text` pattern and is the one allowed exception to TT-AC-39's "no game name" rule. Portal copy still uses `{{TITLE}}`. The save key stays the hard-coded `tea_bakery_save_v1` (§12.2).
**Mark terminology (v1.0, Shahar Q1):** the player's note mark is an **empty cake mold** (UI word "mold"; internal cell states `EMPTY`, `MOLD`, `MOLD_AUTO`, `CAKE`; dump values `empty`/`mold`/`mold_auto`/`cake`). There is no X mark anywhere in v1. In Player Profile quotes, "[mold]" stands in for the profile's cross mark.
**Path note:** files and folders still use the old slug `tea-and-tarts` (this file, `DAY0.md`, `QA_TEST_PLAN.md`, `/workspace/tea-and-tarts/`, `/workspace/audience/tea-and-tarts.md`). They are **not renamed** until the title is final; one rename pass follows the title decision.

Owner: **GD** (T&T Game Design lead). Pre-filled by Pipeline Ops 2026-10-25 08:20 Asia/Jerusalem (UTC+2) from `playbook/templates/spec.md`; v0.2 merged by GD ~08:40; v0.3 = GD response to TT QA's spec review (`QA_TEST_PLAN.md` §0) + SM's desktop-layout and berry-v2 notes, ~09:15 Asia/Jerusalem (UTC+2). Supersedes: v0.2 (backups `.SPEC.v0.1.bak.md`, `.SPEC.v0.2.bak.md` in this folder; `/workspace/tea-and-tarts/spec/SPEC.md` is the committed byte-identical copy of this file from v1.0 on; this file stays canonical).
**Status: LOCKED v1.2, 2026-11-03** (v1.0 locked 2026-10-25; v1.0.2 2026-11-01) (Shahar's answers to Q1–Q3 + Art style relayed by TT Studio Manager via CoS). Changes after lock follow the Playbook change rule (version bump + changelog + broadcast). Non-blocking follow-ups: "Post-lock follow-ups" at the end of this file.

**Player Profile:** `/workspace/audience/tea-and-tarts.md` **v1 (2026-10-25)**. `TT:<line>` = line in that file. **v1 counts as final for spec lock**: Playbook stage 1 exit (PLAYBOOK.md:63) says *"A pre-launch profile v1 (no live data) **counts as final for spec lock**… Growth revisits it against real portal data at the first post-launch retro. (CoS 10-25)"*, logged in `playbook/CHANGELOG.md` v1.3 ("approved by CoS"). If the profile version changes, re-check every Profile ref.

Legend: **KNOWN** = locked by Shahar/CoS/SM. **DECIDED** = GD decision (one-line rationale; Shahar/SM may override at lock). **OPEN-SHAHAR** = needs Shahar (none open at v1.0; Q1–Q3 answered, end of file). **TODO(owner)** = waiting on another owner. **IN** = v1 (first-on-CrazyGames build). **OUT** = post-v1 (§15). `QA §0.x.y` = item in TT QA's spec review (`QA_TEST_PLAN.md` §0).

Changelog
- 2026-10-25 v0.1: pre-filled skeleton (Pipeline Ops). → for GD; cc GROWTH, QA, ART, PO.
- 2026-10-25 v0.2: GD merge. Lean IN/OUT list; D-01..D-22 decided except 3 Shahar questions; profile-final ruling cited; 44 px AC; worked 5×5 example; hints, mistakes, meta, daily, ads, analytics, CG SDK, save, art state matrix, portal copy (no title); ACs TT-AC-16..45; tunables + `spec_assert.py`; title → TBD. → TT Studio Manager, GROWTH, QA, ART, GB, PO.
- 2026-10-25 v0.3: GD response to TT QA review. All 8 not-verifiable + 14 vague ACs rewritten as binary/measurable (§13); old-title/name ban for all user-facing text (TT-AC-39; ch4 card "Jam tarts" stays per SM, generic "tart(s)" allowed in recipe names); tutorial time tunable = range 20–60 s (estimate 40); streak defined exactly with 11 test vectors (§7.1, checked by `spec_assert.py`); post-chapter-8 end state (§7.2); ch1 hints stay free on replay; D-04 updated: 9×9 allowed on desktop/landscape incl. the 800×450 CG embed (Art wide layout: 45.56 px cells, verified in `spec_assert.py`), never on phones; berry v2 piece; new ACs TT-AC-46..52 (performance, idle hint pulse, rotate/too-small message, save timing, 9×9 desktop cells, post-ch8, no scaled portrait in landscape); portal copy placeholder `{{TITLE}}`; QA hook list H1–H6 adopted (§13.1); QA §0.1/§0.2 rulings (§14). → TT QA, TT Studio Manager, GROWTH, ART, GB, PO.
- 2026-10-25 v0.3.1 (patch, SM-approved): build requirements BR-1..BR-3 added to §13.1 (release perf marks + `pkd:perf` console lines; debug runtime date/second-daily-attempt; debug runtime session clock + log of every midgame decision), referenced in TT-AC-46, TT-AC-29, TT-AC-17; build name placeholder "Bakery Logic Puzzle" (config/name + page title) with an explicit TT-AC-39 exception. AC count unchanged (52). → TT QA, TT Studio Manager, GB.
- 2026-10-25 **v1.0 LOCKED**: Shahar's answers (via TT Studio Manager / CoS): **Art** = style "B-revised" (style B + soft padded tiles instead of grid lines, empty cake mold instead of the X mark, extra cake polish; final look = Art deliverable, Shahar OKs visuals; not a spec blocker; D-17, §10). **Q1** tap order = empty → mold → cake → empty, "cake first" setting kept; every X-mark reference replaced by the mold (rules, onboarding, hints, controls copy, cell states, ACs, auto-X → auto-mold, right-click). **Q2** no analytics at launch: events stay as no-op hooks; TT-AC-34..36 moved to §13.3 post-launch (not gating); new gating TT-AC-53 (no network analytics calls); privacy-notice question moot for v1. **Q3** no lives, no fail state (all life/fail-state references removed). Title stays `{{TITLE}}` (portal copy) / "Bakery Logic Puzzle" (config/name). `spec_assert.py` adds a retired-mark copy check. 53 ACs (50 gating + 3 post-launch). → TT QA, TT Studio Manager, GROWTH, ART, GB, PO, CoS.
- 2026-10-25 **v1.0.1 (still LOCKED)**: clarification only, no gameplay change. TT-AC-53 reworded: "0 `sendBeacon`/`fetch` from game code; any `sendBeacon` must come from the CG SDK and target hosts on `/workspace/tea-and-tarts/portal/CG_NETWORK_ALLOWLIST.md`" (the CG SDK itself beacons to `cza.crazygames.com/event` on live CG, so the v1.0 "0 sendBeacon" would fail there); intent unchanged (no analytics network calls from our code). The 5-min interstitial floor (U2: session_s ≥300 s, ≥180 s gap; TT-AC-17) is **reconfirmed by TT Studio Manager** as written. → TT QA, TT Studio Manager, GB, PO.
- 2026-11-01 **v1.0.2 (still LOCKED)** (ruled by TT Studio Manager): (1) ch5 recipe card "Bakewell slice" → **"Cherry Bakewell"** (round tart, fits Art's round-cake trade-dress rule; Build already ships it); ch3 "Lemon drizzle" keeps its name and is drawn round (§3.2). (2) D-02 on phones: rules text **≤3 lines at ≥16 px** (at 390 px it wraps to 3 lines at 16 px; 15 px would break the TT-AC-07 body-text minimum); board stays ≥352 px, targets ≥44 px; the space comes from padding, never font or board. (3) TT-AC-53 clarifying note: the engine loader's same-origin fetches of the game's own export files (index.wasm, index.pck, other export files) are allowed; "game code" = our GDScript and JS only (core rule unchanged). (4) §10: style B-revised approved by Shahar for production as **B2**; canonical = `art/*_B2.png` + `docs/art/STYLE_GUIDE.md`; Art item closed; title is the only open item. Post-lock follow-ups updated (GB §4 worked example validated). `spec_assert.py` asserts the D-02 3-line rule. → TT QA, TT Studio Manager, GB.
- 2026-11-03 **v1.1 (LOCKED; Shahar request: "more structure, industry standard")**: gameplay-structure change, rules unchanged. (1) **Level map** (§3.7, §9): every chapter board is a numbered **level 1–96** (level = (chapter − 1) × 12 + board); a Levels screen shows the 8 chapters as groups of 12 level buttons with their best stars; solved levels replay, the first unsolved level plays, later levels are locked (sequential unlock); the board title is "Level N" (was "Chapter N · Tray b/5"); "Replay a chapter" is replaced by the Levels screen (Home button "Levels", shown once any level is solved). (2) **More content** (§3.2, D-05): chapters grow from 5 to **12 levels** (8 × 12 = **96 chapter boards**, ≈121 min, was 40 / ≈50 min); **b1–b5 of every chapter are the v1.0.2 boards, unchanged** (same ids, same boards); b6–b12 come from the same validated packs, same ramp rules (breather after hard, ≤1 G4 per chapter). Chapter end (recipe card + décor + midgame slot) moves to the 12th level; Bake of the Day unlocks when chapter 1 (12 levels) is done. (3) **Stars** (§3.6, D-09 revised): each solved level earns **1–3 stars**: ★ baked, ★★ baked with no hints, ★★★ no hints and no conflict shown; best result kept per level (replays can raise it, never lower it); shown on the solved card, the level map, and Home ("Stars: x / 288"). Stars are a mastery mark only: **no currency, nothing to buy or spend, no time component** (D-16 unchanged: no timer during play). Daily shows its stars on the solved card but stores none. New ACs TT-AC-54..56; TT-AC-34/35/51 updated (12 boards, level map). Best times / leaderboards stay OUT. Follow-up for SM (not blocking): chapter-end is now every ~9–20 min, so midgame interstitials are rarer than in v1.0.2 (rules unchanged). → TT QA, TT Studio Manager, GROWTH, GB, PO.
- 2026-11-03 **v1.2 (LOCKED; Shahar request)**: **one cake per chapter** (D-03 revised, §10): each chapter's board uses the B2 cake of its recipe card: ch1 scone, ch2 victoria (slice), ch3 lemon, ch4 apricot (jam tart), ch5 bakewell, ch6 berry v2, ch7 custard (crumble), ch8 macaron; Bake of the Day uses **chocolate**; debug/free boards keep berry v2. The level map shows each chapter's cake next to its heading. All 9 sprites already ship in `assets/board/` (B2 style: ink outline + cream halo); no new art. Readability is measured on the sprite pixels (TT-AC-33 updated; `tests/test_cake_contrast.gd`): cream halo silhouette ≥98% of the outline, ink outline ≥94%, ink ≥3:1 on all 9 patches. Measured: halo 99–100% on all 9; ink 95–100% (lowest: victoria 0.95, macaron 0.95, because the strawberry on the slice and the macaron feet have no ink outline: Art follow-up, non-blocking). Per-region pastry variety stays OUT. → TT QA, TT Studio Manager, ART, GB.

---

## 1. Pitch + core loop
**KNOWN:** A Queens-style logic puzzle in a cozy **inland village tea room** (no coffee shop, no harbour/sea: Sudoku Dash owns that look, TT:81). Place cakes on a baking tray so there is exactly one cake in every row, every column and every color region, and no two cakes touch, not even diagonally. Every board has exactly one solution, reachable by logic alone. Boards take 1–2 min; **96 numbered levels** on a level map, 12 levels make a chapter; each level earns 1–3 stars (no hints / no conflicts, never time); a daily "Bake of the Day" board builds a gentle streak. Calm: no timer, no fail state, rewarded hints instead of forced ads. Game #4 of Pikeydi (PKD), Model A browser game: Godot 4.3 → web export → CrazyGames first, then Poki / GameDistribution; no paid UA.
**DECIDED** fiction: board = baking tray; region = a patch of dough (fiction only, see D-18); "never touching" = they'd stick together in the oven; solving "bakes" the tray (golden reveal + steam puff, TT:70).
**Core loop:** boot → PKD intro → board → set empty molds / place cakes → tray bakes (1–3 stars) → next level → after the 12th level of a chapter, chapter end: recipe card + 1 décor piece (+ possible interstitial from chapter 1 end on, §12) → next chapter. Daily board alongside, unlocked after chapter 1.
- **D-01 meta — DECIDED:** each chapter unlocks **1 recipe card + 1 décor piece**; a Recipe Book screen shows the cards; décor appears on a fixed tea-room counter shelf on Home and the chapter-end screen (no placement, no choices). No energy, no build timers, no currency. *Rationale:* Growth/SM point and TT:53 (light meta; Azur postmortem −22% retention from a heavy meta).

## 2. Rules (every on-screen rule has an acceptance ID)
| ID | Rule | Status | AC |
|---|---|---|---|
| R1 | Each row contains exactly one cake. | KNOWN | TT-AC-01 |
| R2 | Each column contains exactly one cake. | KNOWN | TT-AC-01 |
| R3 | Each color region contains exactly one cake. An N×N board has exactly N regions, each 4-connected. | KNOWN | TT-AC-01, -04 |
| R4 | No two cakes touch horizontally, vertically or diagonally (8-neighbourhood). | KNOWN | TT-AC-01 |
| R5 | Every shipped board has exactly one solution. | KNOWN | TT-AC-02 |
| R6 | Solved = N cakes placed and R1–R4 hold; detected automatically on every change; no "submit". Solved is final (no undo past it). | DECIDED | TT-AC-01, -15 |
| R7 | Empty molds (player or auto) are notes only, never validated, never block a cake. | KNOWN (Q1) | TT-AC-06, -22 |
| R8 | There is no fail state: no lives, mistake counter or timer. A rule-breaking placement is allowed and shown as a conflict (§5, D-10). | KNOWN (Shahar Q3) | TT-AC-21 |

- **D-02 rules wording — DECIDED.** On-screen (phones: **≤3 lines, ≥16 px**; at 390 px the text wraps to 3 lines at 16 px, and 15 px would break the TT-AC-07 body-text minimum; board stays ≥352 px and targets ≥44 px; the space comes from padding, never font or board size; v1.0.2): **"One cake in every row, column and color."** / **"Cakes can't touch — not even corners — or they'll stick in the oven!"** *Rationale:* shortest wording that matches LinkedIn Queens players' mental model (TT:25-27) and keeps the fiction in one clause.
- **D-03 piece naming/variety — DECIDED (v1.2 revised):** UI word **"cake"**; **one cake sprite per chapter**, the cake of that chapter's recipe card (§10 table; Bake of the Day = chocolate; debug boards = berry v2). Every board still shows a single sprite (all cakes on a board look the same). Per-region pastry variety is OUT. *Rationale (v1.2):* each chapter of the level map gets its own look (progress you can see) at zero art cost, since all 9 B2 cakes already ship; readability is gated by TT-AC-33 on every sprite. *Original rationale:* brief/profile use "cake" (TT:69); the old title and "Pop-Tart" are banned in user-facing text (TT-AC-39); generic "tart(s)" in recipe names is fine.
- **D-18 "dough patch" term — DECIDED:** UI and copy say **"color"/"color region"** (genre-standard, US English for the CG US/UK core, TT:31); "dough patch" stays internal fiction only. *Rationale:* Bakedoku's copy is "every coloured patch of dough" (TT:102 "we must look distinct").

## 3. Tables: levels / content / economy
**No currency, coins or lives (D-09).** Stars (v1.1, §3.6) are a per-level mastery mark, never spent. The "economy" is content + hints + ads; all numbers below are in the machine-readable tunables block (§3.5) and checked by `spec_assert.py` (this folder; `python3 spec_assert.py`, exits non-zero on failure).

### 3.1 Board sizes, layouts and the 44px rule (D-04 — KNOWN, SM rulings 2026-10-25, updated v0.3)
Two layouts (§9): **phones** (portrait 390×844 column, 16 px side margins → 358 px board) and **wide** (desktop and any landscape viewport ≥440 CSS px tall, incl. the CG embeds: Art's mock `art/mocks/desktop_wide_9x9_1920x1080.png`, board fills the height on the left: tray outer margin 8 px + tray inner margin 12 px top and bottom → board = H − 40; recipe card + tools on the right). Cell = board / N, in CSS px.
| Size | Phone 390×844 | Phone landscape 844×390 (compact: H − 36) | Wide 800×450 (CG) | Wide 1280×720 | Wide 1280×800 | Offered on |
|---|---|---|---|---|---|---|
| 5×5 | 71.6 | 70.8 | 82.0 | 136.0 | 152.0 | all |
| 6×6 | 59.7 | 59.0 | 68.3 | 113.3 | 126.7 | all |
| 7×7 | 51.1 | 50.6 | 58.6 | 97.1 | 108.6 | all |
| 8×8 | **44.75** | 44.25 | 51.3 | 85.0 | 95.0 | all |
| 9×9 | 39.8 ❌ | 39.3 ❌ | **45.56** ✅ | 75.6 | 84.4 | wide only (never on phones) |
(Wide cells assume the 8+12 px margins scale no larger than in Art's mock; at 1280×720 the tray margins are still 40 CSS px total. GB may scale margins up on large screens as long as TT-AC-50 holds.)
**Verification of Art's claim:** the mock's generator (`art/tools/build_followup.py` `wide()`) uses a tray from y=8 to y=442 (434 px) with a 12 px inner margin → board 410 px → 410/9 = **45.56 px** at 800×450. `spec_assert.py` recomputes it. Headroom: 9×44 = 396 px, so total vertical margins at 450 px may be at most **54 px** (mock uses 40). 9×9 at 844×390 (phone landscape) is 39.3 px, so 9×9 is never offered on phones.
Rule: a board size is offered only if its cell is ≥44 CSS px in the current viewport; **no exceptions** (TT-AC-07, TT-AC-50). **v1 content is unchanged: no 9×9 boards ship in v1** (chapters and daily must be identical on every device); 9×9 is the post-v1 desktop "Master trays" bonus, and the layout + AC-50 make it ready.

### 3.2 Chapters (D-05, D-06 — DECIDED; v1.1: 12 levels per chapter)
8 chapters × 12 levels = **96 chapter boards** (levels 1–96 on the level map, §3.7), + **400-board daily pool** (≥13 months). Grades from §16.3 (G1 easiest … G4). One easy "breather" board follows each hard one (TT:52). **b1–b5 = the v1.0.2 boards, unchanged**; b6–b12 added in v1.1 (built by `tools/build_chapters.gd` in a second pass, so b1–b5 stay byte-identical).
| Ch | Levels | Recipe card | Décor piece | Sizes (b1–b12) | Grades (b1–b12) | Est. chapter time |
|---|---|---|---|---|---|---|
| 1 | 1–12 | Scones & clotted cream | Floral teapot | 5 ×12 | 1,1,1,1,2, 1,2,1,2,1,2,2 (b1–b3 = tutorial trays with pre-placed cakes) | ~8.8 min |
| 2 | 13–24 | Victoria sponge | Tiered cake stand | 5,6,5,6,6, 5,6,6,5,6,6,6 | 2,2,1,2,2, 2,2,1,2,2,1,2 | ~11.0 min |
| 3 | 25–36 | Lemon drizzle | Gingham tablecloth | 6 ×12 | 2,2,1,2,3, 2,2,1,3,2,1,3 | ~12.0 min |
| 4 | 37–48 | Jam tarts | Lace doily + teacups | 6,7,6,7,7, 7,6,7,7,6,7,7 | 2,2,1,2,3, 2,2,1,3,2,1,3 | ~14.7 min |
| 5 | 49–60 | Cherry Bakewell | Vase of sweet peas | 7 ×12 | 2,3,1,2,3, 2,2,1,3,2,1,3 | ~16.0 min |
| 6 | 61–72 | Strawberry shortcake | Bunting garland | 7,8,7,8,8, 8,7,8,8,7,8,8 | 2,2,1,3,2, 2,3,1,2,3,1,3 | ~18.7 min |
| 7 | 73–84 | Apple crumble | Cuckoo clock | 8 ×12 | 2,3,1,3,2, 2,3,1,2,3,1,3 | ~20.0 min |
| 8 | 85–96 | Macarons | Copper kettle | 8 ×12 | 3,2,3,4,2, 3,2,3,2,3,1,3 | ~20.0 min |
Est. time = sum of median targets (§3.3; tutorial trays at their 40 s estimate). **Total ≈ 121 min of chapter content + daily** (v1.0.2: ≈50 min). Names are placeholders for ART/copy; all are inland tea-room items; no name may contain the old title, the working name, LinkedIn, Meowdoku or "Pop-Tart" (`spec_assert.py` checks the list); generic "tart(s)" is allowed (ch4 "Jam tarts" stays, SM ruling). **v1.0.2:** ch5 = "Cherry Bakewell" (round tart, Art's round-cake trade-dress rule); ch3 "Lemon drizzle" keeps its name and is drawn round. After chapter 8: §7.2.

### 3.3 Target solve times (median, first-time solver; INFO at the Thin-slice playtest, not a gate)
| Size | 5×5 | 6×6 | 7×7 | 8×8 | 9×9 (post-v1) |
|---|---|---|---|---|---|
| Median target | 45 s | 60 s | 80 s | 100 s | 130 s |
| Acceptable band | 20–90 s | 30–120 s | 40–150 s | 60–180 s | — |
**Tutorial trays (ch1 b1–b3): range 20–60 s each, estimate 40 s** (tunable `tutorial_board_s` = {min 20, est 40, max 60}). The estimate feeds the content sums; 60 s is the design ceiling from TT:47/TT:127. It is not a QA gate for humans (no naive testers): QA gates the scripted part (TT-AC-05), and Growth checks the human part post-launch via CG conversion ≥80% (profile §7 A1).

### 3.4 Hints, daily, ads (numbers; rules in §6/§7/§12)
| Item | Value |
|---|---|
| Hints on chapter-1 boards | unlimited, free, no ads — **also on replay** (the rule follows the board) |
| Free hints, chapter 2+ and daily | 1 per board (resets each board; not banked; replays included) |
| Rewarded hints | unlimited after the free one, 1 ad = 1 hint; hidden if the ad is unavailable/adblocked |
| Interstitial (midgame) | only on the chapter-end → next transition, from the chapter 1 end on; session_s ≥300 (U2); ≥180 s since the previous midgame request (game-enforced); never after the daily; never if a rewarded ad played since that chapter's 5th board started |
| Daily pool | 400 boards; sizes by weekday Mon 6, Tue 6, Wed 7, Thu 7, Fri 7, Sat 8, Sun 8; grade ≤2 weekdays, ≤3 weekends |
| Streak grace | forgiven misses ≥7 days apart (U1, §7.1) |

### 3.6 Stars (v1.1 — DECIDED, D-09 revised)
| Stars | Condition (per solve of a chapter level) |
|---|---|
| ★ (1) | Tray baked. |
| ★★ (2) | Baked with **no hint** used on this board (free, rewarded or "Show me"). |
| ★★★ (3) | Baked with no hint **and no conflict shown** on this board (a conflict = a new rule-breaking cake that triggered the D-10 highlight). |
- **Never time-based** (D-16: no timer during play; "Baked in m:ss" stays an info line). No fail state: 1 star is always earned.
- **Best result kept** per board id in the save (`progress.stars`); replays can raise it, never lower it. A solved board without a stored value (v1.0.x saves) counts as 1 star.
- Shown on: the solved card (3 drawn stars + a one-line tip when < 3: how to get more), each level button on the level map, each chapter heading ("x/36 stars"), Home ("Stars: x / 288"). The daily solved card shows its stars, but the daily stores none.
- Stars buy nothing, unlock nothing and gate nothing (no currency, D-09). *Rationale:* genre-standard mastery/replay hook (casual level maps, Star Battle apps) without time pressure (TT:65) and without a fail state (R8).
- Tutorial trays (c1-b1..b3) use the same rule; ch1 hints stay free but still count as hints for stars.

### 3.7 Level map (v1.1 — DECIDED)
- Level number = (chapter − 1) × 12 + board (1–96). Board ids stay `cN-bM` (save, analytics, QA hooks unchanged).
- Screen "Levels" (`level_map`): back button, title, total stars; one group per chapter (heading "Chapter N · <recipe> · x/36 stars") with 12 level buttons (4 per row on phones, 6 on wide; each ≥72×72 px with the level number and its best stars). Scrolls vertically; opens scrolled to the next level.
- **Sequential unlock:** a level is open if it is solved or it is the first unsolved level; later levels show a lock and do nothing. The next level is the primary (raspberry) button.
- Tap: solved level → replay (mode `replay`, §5 replay rules); next level → play (restores saved marks).
- Home: "Continue · Level N" (primary), Bake of the Day, **Levels** (once any level is solved; replaces "Replay a chapter"), Recipe Book, Settings, and "Stars: x / 288".
- Board title: "Level N" (top bar / wide panel). The chapter-progress dots show the 12 boards of the current chapter.

### 3.5 Tunables (source of truth for `spec_assert.py`; GB copies into `game/tunables.json`)
```json tunables
{
  "viewport": {"portrait_w": 390, "portrait_h": 844, "side_margin": 16, "min_tap_px": 44, "min_text_px": 12, "label_text_px": 14, "body_text_px": 16, "min_button_h": 48},
  "wide_layout": {"tray_outer": 8, "tray_inner": 12, "compact_below_h": 440, "compact_total_v_margin": 36, "panel_min_w": 240, "tray_left": 40, "panel_gap": 28,
                  "check_viewports": [[800,450],[821,462],[907,510],[1280,720],[1280,800]], "phone_landscape": [844,390]},
  "mobile_max_size": 8,
  "wide_only_sizes": [9],
  "v1_content_max_size": 8,
  "median_solve_s": {"5": 45, "6": 60, "7": 80, "8": 100, "9": 130},
  "tutorial_board_s": {"min": 20, "est": 40, "max": 60},
  "chapters": [
    {"id": 1, "sizes": [5,5,5,5,5,5,5,5,5,5,5,5], "grades": [1,1,1,1,2,1,2,1,2,1,2,2], "tutorial": [1,2,3], "recipe": "Scones & clotted cream", "decor": "Floral teapot"},
    {"id": 2, "sizes": [5,6,5,6,6,5,6,6,5,6,6,6], "grades": [2,2,1,2,2,2,2,1,2,2,1,2], "recipe": "Victoria sponge", "decor": "Tiered cake stand"},
    {"id": 3, "sizes": [6,6,6,6,6,6,6,6,6,6,6,6], "grades": [2,2,1,2,3,2,2,1,3,2,1,3], "recipe": "Lemon drizzle", "decor": "Gingham tablecloth"},
    {"id": 4, "sizes": [6,7,6,7,7,7,6,7,7,6,7,7], "grades": [2,2,1,2,3,2,2,1,3,2,1,3], "recipe": "Jam tarts", "decor": "Lace doily and teacups"},
    {"id": 5, "sizes": [7,7,7,7,7,7,7,7,7,7,7,7], "grades": [2,3,1,2,3,2,2,1,3,2,1,3], "recipe": "Cherry Bakewell", "decor": "Vase of sweet peas"},
    {"id": 6, "sizes": [7,8,7,8,8,8,7,8,8,7,8,8], "grades": [2,2,1,3,2,2,3,1,2,3,1,3], "recipe": "Strawberry shortcake", "decor": "Bunting garland"},
    {"id": 7, "sizes": [8,8,8,8,8,8,8,8,8,8,8,8], "grades": [2,3,1,3,2,2,3,1,2,3,1,3], "recipe": "Apple crumble", "decor": "Cuckoo clock"},
    {"id": 8, "sizes": [8,8,8,8,8,8,8,8,8,8,8,8], "grades": [3,2,3,4,2,3,2,3,2,3,1,3], "recipe": "Macarons", "decor": "Copper kettle"}
  ],
  "boards_per_chapter": 12,
  "v102_boards_per_chapter": 5,
  "chapter_minutes_range": [8, 21],
  "min_total_content_min": 100,
  "cakes": {"by_chapter": ["scone", "victoria", "lemon", "apricot", "bakewell", "berry", "custard", "macaron"], "daily": "chocolate", "debug": "berry", "min_halo_coverage": 0.98, "min_ink_coverage": 0.94},
  "stars": {"max_per_board": 3, "no_hint": 2, "no_hint_no_conflict": 3, "time_based": false, "currency": false},
  "level_map": {"unlock": "sequential", "cols_phone": 4, "cols_wide": 6, "button_px": 72},
  "daily": {"pool": 400, "epoch": "2026-11-02", "sizes_mon_to_sun": [6,6,7,7,7,8,8], "max_grade_weekday": 2, "max_grade_weekend": 3, "forgiven_miss_min_gap_days": 7},
  "hints": {"free_per_board": 1, "chapter1_unlimited_free": true, "chapter1_free_on_replay": true, "rewarded_per_ad": 1, "idle_pulse_s": 30, "idle_pulse_max_per_board": 1},
  "ads": {"first_interstitial_after_chapter": 1, "min_session_s_before_interstitial": 300, "min_gap_between_midgame_s": 180, "interstitial_after_daily": false, "rewarded_uses": ["hint"]},
  "save": {"key": "tea_bakery_save_v1", "debounce_ms": 1000, "qa_tolerance_ms": 1100},
  "perf": {"cpu_throttle": 4, "tap_to_frame_p95_ms": 100, "frame_p95_ms": 33.4, "long_task_ms": 50, "transition_ms": 1000, "transition_long_task_ms": 200, "heap_growth_mb_20_boards": 20},
  "max_grade": 4,
  "banned_user_text": ["\\btea[\\s_-]*(&amp;|&|\\+|and|'?n'?)[\\s_-]*tarts?\\b", "tea-bakery", "linkedin", "meowdoku", "\\bpop[\\s_-]*tarts?\\b"],
  "retired_mark_text": ["✕", "\\bcross(ed|es)?\\s+(it|them|these|out)\\b", "\\bx[ -]?marks?\\b"]
}
```

## 4. Worked example (one full board) — DECIDED, validated
Replaces the v0.1 ungraded candidate. Generated with the throwaway Python prototype (`proto/trace.py`, same method as §16.2); the exact solver found **exactly 1 solution**; the §16.3 ladder solves it with no guessing, hardest step T4 → **grade 2**. Suitable for ch1 b5 or ch2. GB must re-validate it with the shipped GDScript validator (TT-AC-02/03).
```
     A B C D E          regions: a = strawberry (big), b = butter (column E strip), c = pistachio (2 cells),
 1   a a a a b                   d = lavender, e = honey
 2   a a a a b          solution: C1, E2, B3, D4, A5
 3   c c a a b
 4   e e a d d
 5   e d d d d
```
| Step | Technique | What happens | Hint text (plain words, §6) |
|---|---|---|---|
| 1 | T3 confinement | Butter (E1–E3) lies only in column E → mold E4, E5 | "All of butter is in column E, so set empty molds on the rest of column E." |
| 2 | T3 confinement | Pistachio (A3, B3) lies only in row 3 → mold C3, D3, E3 | "Pistachio sits only in row 3, so set empty molds on the rest of row 3." |
| 3 | T4 shared neighbour | Row 3's only spots are A3/B3; A2, B2, A4, B4 touch both → mold | "Whichever pistachio cell gets the cake would touch these four cells, so set empty molds on them." |
| 4 | T1 last spot | Honey (A4, B4, A5) has only A5 left → cake A5; auto-mold col A, row 5, B4 | "Honey has one free cell left, so its cake goes here." |
| 5 | T1 | Row 3: A3 now a mold → cake B3 | "Row 3 has one free cell left, so its cake goes here." |
| 6 | T1 | Row 4: only D4 left → cake D4 | "Row 4 has one free cell left, so its cake goes here." |
| 7 | T1 | Row 2: only E2 left → cake E2 | "Row 2 has one free cell left, so its cake goes here." |
| 8 | T1 | Row 1: only C1 left → cake C1 → **tray bakes** | "Row 1 has one free cell left, so its cake goes here." |
Check: one per row/col/region (C1 a, E2 b, B3 c, D4 d, A5 e); no touching (row-to-row column gaps 2, 3, 2, 3).

## 5. Edge cases — DECIDED
| Case | Behaviour |
|---|---|
| Cake on a mold cell | Cycle continues (mold → cake); allowed. |
| 2nd cake in a row/col/region, or touching | Allowed; both cakes show conflict (D-10); no penalty. |
| Undo after solved | Blocked; solved is final (R6). |
| Auto-mold on, cake removed | Auto-molds generated by that cake are removed unless another cake or the player also set them. |
| Tab hidden / blurred mid-board | State saved; `gameplayStop`; active-time counter paused; audio suspended (starter `PKD_AUDIO`). |
| Resize / rotate mid-board | Re-layout (phone ↔ wide), state kept; if the cell would be <44 px, the too-small message covers the board (§9, TT-AC-48). |
| Daily across local midnight | The daily is the one for the local date when it was opened; finishing after midnight counts for that date (U1, V9). |
| Returning player | Board with saved marks, else next unsolved chapter board, else Home (TT-AC-23). |
| All chapters done | §7.2. |
| Device clock changed / timezone | Accepted; nothing to exploit (no currency). Streak per U1: never shortened by moving the clock back (V10). |
| Date before epoch / beyond pool | Index clamps to 0 before epoch; wraps modulo pool size after; CI warns 60 days before wrap. |
| Corrupt / unreadable save | Back up the raw string to `<key>_corrupt`, start fresh, no crash. |
| Replay a solved chapter board | Allowed from the chapter list; no midgame, no duplicate rewards, no `chapter_*` events (only `board_*` with `is_replay`); hint rules follow the board (ch1 free; ch2+ 1 free then rewarded). The daily is not replayable. |
| Hint with a wrong cake/mold on board | The hint first fixes the wrong mark (§6). |
| Ad fails / adblock / no fill | Rewarded button hidden (free hint still works); midgame skipped silently; no error UI. |

- **D-10 conflict feedback — DECIDED: Option A** (live). Rule-breaking cakes get a dashed berry outline + a small "!" badge, and the shared row/column/region or the touching pair gets a soft tint; never colour alone. *Rationale:* genre default, calm teaching without a fail state. A solution-based "check" toggle is OUT.
- **D-11 daily rollover — DECIDED:** **device local midnight**; board for a date = `pool[(local_date − 2026-11-02) mod 400]`, so everyone gets the same board on the same calendar date. *Rationale:* matches "today's puzzle" expectation; no server needed.

## 6. Onboarding *(Profile ref required)*
**Profile ref (tea-and-tarts.md v1):**
- §8 Spec hooks, TT:127: *"Onboarding: no menu. A 5×5 tutorial board teaching 3 rules in 3 taps. Single-tap cycle (empty → [mold] → cake). The first board is solvable in under 60 s. No ads before chapter 1 ends."*
- §3, TT:47: *"Time to first fun: under 15 s to the first placed cake. The first board (5×5 tutorial) is solved within 60 s [A]."*
- §1 Skill, TT:30: *"Queens players know the rules already. Everyone else needs a 3-step tutorial [A]."*
- §2 Input, TT:40: single tap/click cycles empty → [mold] → cake, no double-tap. §4 quit points, TT:59-64 (forced ads, tiny cells, mis-taps).
- §7 A1, TT:113: CG conversion ≥80%; if below, cut the tutorial to 2 taps.

**DECIDED flow (IN):**
1. Boot → **PKD studio intro** (the Pikeydi → PKD logo animation, 1.93 s, skippable by tap/click/key) from the starter `pkd-godot-web-starter` (`/workspace/pipeline-ops/starter/pkd_intro/`, overlay mode per `/workspace/pikeydi-logo/godot/INTEGRATION.md` §2A; already in the T&T working copy `/workspace/tea-and-tarts/pkd_intro/`). The board builds under the intro; `loadingStop` and the first `gameplayStart` fire only after the intro's `finished`.
2. **First launch: straight onto ch1 b1. No title screen, menu or chapter map before it (D-14).** Returning players boot into the board with saved marks, else the next unsolved chapter board, else Home (TT-AC-23); Home is one tap away (top-left).
3. Three tutorial trays (5×5, pre-placed "given" cakes on a plate, so each tray needs 1–2 placements). Each teaches **one rule** with a one-line coach bubble and a pulsing target cell:
   - **b1 Rows & columns:** 4 cakes given; one row/column empty → place the last cake (teaches tap → empty mold → cake). Target: first cake ≤15 s after the intro.
   - **b2 Colors:** two free cells in the empty row/column; only one is in the color that still needs a cake.
   - **b3 No touching:** two candidates; one touches a given cake diagonally → set an empty mold on it, place the other. Coach shows auto-mold.
4. b4–b5 are normal G1/G2 trays with no coach. On **every** unsolved board, the Hint button pulses once after 30 s without input (max once per board; TT-AC-47).
5. Every solve plays the bake reward, then **the next board is interactive ≤2.0 s later** after a ≤1.5 s skippable "Baked!" card (TT-AC-25).
6. No ads of any kind until chapter 1 is finished (TT:76, TT-AC-16).
- **D-12 controls — KNOWN (Shahar Q1, 2026-10-25):** single tap/click cycles **empty → empty mold → cake → empty** (the mold is the note mark; profile TT:40/TT:127 order, LinkedIn Queens convention); right-click on desktop toggles the empty mold directly (empty ↔ mold); no double-tap, no long-press. Settings toggle "Tap order: cake first" swaps the order (empty → cake → mold → empty). Drag-to-paint molds is **OUT** (v1.1).
- **D-13 auto-mold — DECIDED: ON by default**, toggle in Settings ("Auto-molds"). Auto-molds are drawn lighter than player molds. *Rationale:* fewer taps on phones (TT:62 mis-taps); it only automates the trivial T2 step, so purists lose nothing.
- **D-14 — DECIDED:** confirmed, no menu before board 1 (TT:127; CG "1 click to gameplay").

## 7. Session length *(Profile ref required)*
**Profile ref (tea-and-tarts.md v1):**
- §3, TT:45: *"Typical session: 10–20 min = 5–10 boards [A]."* TT:48: stopping points = board end ("tray baked") and chapter end (recipe card + décor). TT:49: return trigger = daily Bake of the Day, same for everyone, with a streak.
- §3 Session design, TT:52-54: 5-board chapters, ramp with breather boards, light recipe-book meta, streak on Home.
- §8 Spec hooks, TT:128: 1–2 min boards × 5-board chapters; 1 recipe + 1 décor per chapter; daily + streak; interstitials at chapter ends only; analytics events.
- §4 Tone, TT:65: *"No timer by default; best time is optional [A]."*
- §7 A2/A3/A5, TT:114-117: playtime ≥10 min; D1 7–8% expected; chapter funnel.

**DECIDED:**
- A session = 5–10 levels, about one chapter (v1.1: ch1 ≈ 9 min, later chapters 11–20 min) + the daily (~1–1.7 min) → 10–20 min target. Level end (solved card with stars) and chapter end are the stopping points; the chapter-end screen offers "Next chapter" (primary) and "Home".
- Return trigger: **Bake of the Day** (unlocked after chapter 1), streak counter on Home and on the daily's solved card. Missing a day: forgiven automatically if the previous forgiven miss is ≥7 days back (exact rule U1, §13.0; vectors §7.1); otherwise the streak restarts with the line "A fresh streak starts today."; best streak and total bakes are kept.
- **D-15 — DECIDED:** **1 daily board**, the same for everyone on the same calendar date (D-11). *Rationale:* LinkedIn-style daily habit (TT:49); 3 boards would compete with chapters.
- **D-16 — DECIDED:** **no timer visible during play.** The solved card shows "Baked in 1:12" (active time) in small text; no best-time tracking or leaderboards (OUT). *Rationale:* TT:65 calm tone; a time readout after solving is harmless and cheap.
- No energy, no waiting, no soft timers.
- Analytics events for the chapter funnel: §12.4.

### 7.1 Streak definition and test vectors (U1; TT-AC-29)
Definition: §13.0 U1. Vectors (dates are device-local; all checked by `spec_assert.py` `streak()`; GB mirrors them in GUT):
| # | Case | Bake dates S | Today | Streak |
|---|---|---|---|---|
| V1 | 3 days in a row, checked same day | 11-02, 11-03, 11-04 | 11-04 | 3 |
| V2 | today not baked yet keeps the streak | 11-02, 11-03 | 11-04 | 2 |
| V3 | one missed day forgiven | 11-02, 11-03, 11-05 | 11-05 | 3 |
| V4 | one missed day, today not baked yet: still alive | 11-02, 11-03 | 11-05 | 2 |
| V5 | 2 missed days in a row: run broken | 11-02, 11-03, 11-06 | 11-06 | 1 (+ "fresh streak" line) |
| V6 | 2 single misses 2 days apart: only the later one forgiven | 11-02, 11-04, 11-06 | 11-06 | 2 |
| V7 | 2 single misses exactly 7 days apart: both forgiven | 11-02, 11-04 … 11-10, 11-12 | 11-12 | 9 |
| V8 | same-day double completion (forced via hook) counts once | 11-02, 11-03, 11-03 | 11-03 | 2 |
| V9 | daily of 11-03 opened 23:58, finished 00:03 on 11-04 | 11-02, 11-03 | 11-04 | 2 (counts for 11-03; the 11-04 daily is still open) |
| V10 | clock moved back 3 days (or timezone change westward) | 11-02, 11-03, 11-04 | 11-01 | 3 (no reduction; no new increment for an already-baked date) |
| V11 | no bakes yet | — | 11-02 | 0 |
All dates 2026. best_streak and total_bakes are checked alongside: in V5 best = 2, total = 3; in V7 best = 9, total = 9.
```json streak_vectors
[
 {"id":"V1","S":["2026-11-02","2026-11-03","2026-11-04"],"today":"2026-11-04","streak":3},
 {"id":"V2","S":["2026-11-02","2026-11-03"],"today":"2026-11-04","streak":2},
 {"id":"V3","S":["2026-11-02","2026-11-03","2026-11-05"],"today":"2026-11-05","streak":3},
 {"id":"V4","S":["2026-11-02","2026-11-03"],"today":"2026-11-05","streak":2},
 {"id":"V5","S":["2026-11-02","2026-11-03","2026-11-06"],"today":"2026-11-06","streak":1,"best":2,"total":3,"fresh_line":true},
 {"id":"V6","S":["2026-11-02","2026-11-04","2026-11-06"],"today":"2026-11-06","streak":2},
 {"id":"V7","S":["2026-11-02","2026-11-04","2026-11-05","2026-11-06","2026-11-07","2026-11-08","2026-11-09","2026-11-10","2026-11-12"],"today":"2026-11-12","streak":9,"best":9,"total":9},
 {"id":"V8","S":["2026-11-02","2026-11-03","2026-11-03"],"today":"2026-11-03","streak":2},
 {"id":"V9","S":["2026-11-02","2026-11-03"],"today":"2026-11-04","streak":2},
 {"id":"V10","S":["2026-11-02","2026-11-03","2026-11-04"],"today":"2026-11-01","streak":3},
 {"id":"V11","S":[],"today":"2026-11-02","streak":0}
]
```

### 7.2 After chapter 8 (QA §0.2.6) — DECIDED
Completing ch8 shows the normal chapter-end screen (card 8 + kettle), `happytime`, and the usual midgame slot; then, once, an **"All recipes baked"** screen: the 8-card Recipe Book spread + the full counter shelf, one line "New trays every day in Bake of the Day.", and one button "Home". From then on Home shows **Bake of the Day** as the primary button (or "Baked ✓ · back tomorrow" when done) and **"Levels"** (the level map, §3.7; v1.1 replaces "Replay a chapter": any solved level replays with no rewards, no chapter events, no midgame; hint rules follow the board; replays can raise a level's stars). No new content, no endless mode (OUT). Returning players with all chapters done boot to Home. *Rationale:* lean, honest end state; the daily is the retention loop (TT:49).

## 8. Game feel + audio — DECIDED
| Moment | Visual | Audio | Duration |
|---|---|---|---|
| Empty mold placed | mold fades/scales in 0.8→1 | soft tin tap | 90 ms |
| Cake placed | "pop": scale 0→1.15→1, tiny flour puff | soft wooden tick | 150 ms |
| Cake removed | scale 1→0 | — | 100 ms |
| Conflict appears | dashed outline + "!" badge, 2 px wobble once | gentle low "thunk" (no buzzer) | 200 ms |
| Row/col/region completed (correctly) | soft shimmer along it | light chime (pitch rises per completion) | 300 ms |
| Tray solved | cakes turn golden in reading order (40 ms stagger), steam puff, tray glow | oven "ding" | ≤1.5 s, tap to skip |
| Chapter complete | recipe card flips in; décor piece drops onto the counter shelf | soft kettle whistle | ~2.5 s, tap to skip |
| Hint | unit + target cells glow gold, coach bubble slides in | soft bell | 250 ms |
Music: one calm acoustic loop (CC0/licensed), quiet under SFX. **Audio/mute line:** sound and music toggles always reachable (Home + in-board settings); audio starts only after the first gesture; suspends on tab hide/blur/ad (starter `PKD_AUDIO`, D0-14); honours CG `muteAudio` + settings listener (§12). Reduced-motion mode: **OUT of v1**.

## 9. UI layout — DECIDED (two layouts)
KNOWN from playbook/starter: base 390x844 portrait, `canvas_items`/`expand`, safe-area insets via `PkdView`, **44 px minimum tap targets (no exceptions, TT-AC-07/50)**, 12 px absolute minimum text. This audience (TT:21, women 35–65): **body text ≥16 px, labels ≥14 px, buttons ≥48 px tall** (gating in TT-AC-07 since v0.3).
- **Phone layout = portrait viewports** (e.g. 390×844, 360×640, 412×915, 768×1024): top bar 56 px (Home ⌂, "Level 14" or "Bake of the Day", Settings ⚙; v1.1); coach/hint bubble 72 px; board centred, **side margins 16 px (max 19 px, so 8×8 stays ≥44 px)**; tool row 64 px: Undo, Hint (free/🎬 badge), Reset; safe-area padding.
- **Wide layout = every landscape viewport, for every board size 5×5 to 9×9. It is a real re-layout, NOT a scaled-down portrait column** (QA lint: scaling the 390×844 portrait into 800×450 fails both the 44 px target and the 12 px minimum text; the old "portrait column centred on a backdrop" idea in ART_DIRECTION.md §3 is superseded; TT-AC-52) (desktop 1280×720 / 1280×800, CG embeds 800×450 / 821×462 / 907×510, rotated phones): per Art's mock `art/mocks/desktop_wide_9x9_1920x1080.png` (+ `_800x450.png`). Board tray fills the height on the left (tray outer margin 8 px, inner 12 px; tray left edge 40 px); right panel (≥240 px wide, 28 px gap): back/sound/settings row, recipe card with chapter progress ("Level N" + 12 dots, v1.1), rules line (D-02 text), tool buttons Undo, Hint, Reset (≥48 px tall; see §10 mock deltas), Bake of the Day/streak line. Below 440 px height (rotated phones) margins compact to 36 px total. Geometry and cell sizes: §3.1; checked by `spec_assert.py`.
- **Too-small rule:** if the current board's cell would be <44 CSS px in the current viewport (e.g. a viewport smaller than 844×390 in landscape with 8×8), the board is covered by a message "Turn your device upright or enlarge the window to play this tray." with input blocked and state kept (TT-AC-48).
- Screens: Board, Solved card, Chapter end, All-recipes-baked (§7.2), Home (Continue · Level N / Bake of the Day / Levels / Recipe Book / Settings; counter shelf with décor; streak; total stars), Recipe Book (8 cards), Levels (level map, §3.7), Settings (Sound, Music, Auto-molds, Tap order, Reset progress with confirm), modals (Rewarded hint confirm, Reset board confirm).
- Viewport × input matrix: `QA_TEST_PLAN.md` §3 (MX-01..MX-11), adopted.

## 10. Art *(Profile ref required)*
**Profile ref (tea-and-tarts.md v1):**
- §8 Spec hooks, TT:125: *"Art: an inland village tea room in cream, rose and berry tones, with tarts on baking trays. No coffee, harbour or seaside (keep it apart from Sudoku Dash). Large cells; colour-blind-safe dough patterns, not colour alone [A]."*
- §4 Mechanic mapping, TT:68-70: board = baking tray, region = dough patch, piece = cake/tart; solve = *"a golden-brown reveal with a steam puff"*.
- §2 Device, TT:38-39: iPhone Safari 390×844 primary; CG 16:9 embeds. §7 A6, TT:118: if mobile >40%, prioritise portrait and larger cells.
- §4 quit points, TT:62: *"Tiny cells and mis-taps"*. §1, TT:21: primary player 35–65 → larger text.

**Art style: B-revised, APPROVED for production as "B2" (Shahar; v1.0.2, 2026-11-01).** Canonical art = `art/*_B2.png` + `docs/art/STYLE_GUIDE.md`; where they differ from the text below, they win. Art item closed. *(Original lock as "B-revised": Shahar, 2026-10-25.)* Base = ART_DIRECTION.md (`/workspace/tea-and-tarts/art/ART_DIRECTION.md`) style B "Crisp Pastry Flat", with three changes: (1) **softer tiles with padding instead of grid lines** (each cell is a rounded, softly shaded tile with a small gap; the gap and padding sit inside the cell pitch, so the 44 px hit area = the full cell pitch and §3.1 cell math is unchanged; region boundaries stay readable without colour via pattern + a clear region edge); (2) **an empty cake mold instead of the X mark** (fluted tin outline, empty, ink outline); (3) **extra polish on the cakes** (berry v2 base, richer shading/highlights). The final look was an **Art deliverable**, now approved as B2 (above). It is **not a spec blocker**; the rules, states and contrast ACs below bind whatever the final art is.
- Setting: inland village tea room; rose-stripe wallpaper, cream wainscot, window onto green hills, dresser with china and teapots. **No coffee, sea, harbour, boats, lighthouse** (TT-AC-38).
- UI palette (ART): rosewater #F6E3DE bg · clotted cream #FFF8EC panels · earl-grey ink #43283A text/borders/mold outline · raspberry jam #B0365A primary · sage leaf #55724E secondary · pewter tray #A8A09F · cherry alert #A61E2E conflict · honey chip #EDBB80. Ink on cream 12.4:1; cream on raspberry 5.7:1.
- **9 dough-patch regions, each colour + pattern** (ART): strawberry #FA93AC dots · butter #FDE87D diagonal stripes · pistachio #B8DFA6 gingham · lavender #D5BCF1 lattice · honey #DDB664 crumb · blueberry #8E9CC9 shortbread brick · cocoa #AE906C diamond · rhubarb #CB6F91 sprig · vanilla #E8E6D9 pinstripe. Every pair ≥10 ΔE2000 under normal, deuteranopia, protanopia, tritanopia (ART `colorblind_check.png`, `tools/cvd_pairs.json`); clear region edges between padded tiles (final treatment per B-revised art); never a pattern-free mode.
- **Pieces (v1.2): one B2 cake per chapter**, all with the berry v2 treatment (ink outline + cream halo outside it):
  | Ch | Recipe | Piece (`assets/board/cake_<piece>@2x.png`) |
  |---|---|---|
  | 1 | Scones & clotted cream | scone |
  | 2 | Victoria sponge | victoria (slice) |
  | 3 | Lemon drizzle | lemon (round) |
  | 4 | Jam tarts | apricot |
  | 5 | Cherry Bakewell | bakewell |
  | 6 | Strawberry shortcake | berry (berry v2) |
  | 7 | Apple crumble | custard (crumble tart) |
  | 8 | Macarons | macaron |
  | daily | Bake of the Day | chocolate |
  All shapes follow the STYLE_GUIDE shape rules (round, fluted, lattice or slice; the macaron and scone domes are unwrapped). The golden "baked" tint is a colour multiply, so it applies to every piece.
- **Berry v2 (reference piece)** = ART's round fluted cake (approved for style B; `art/tools/ttdraw.py` piece kind `berry2`; comparison sheet `art/small_size_test_berry_v2.png`): lighter crust #F2C584, lighter berries #B83A5E, ink outline, **cream halo #FFF8EC outside the ink outline** for contrast on dark patches. Outer-edge contrast vs dark patches: rhubarb 1.55 → **3.20:1**, cocoa 1.37 → **2.84:1**, blueberry 1.24 → **2.57:1**; on every patch the ink outline (#43283A) carries ≥3:1 (ART: ink on the darkest patch 3.9:1). The old berry is not shipped. No rectangular frosted pastries, sprinkles or "pop" styling (ART_DIRECTION §2, trade-dress rule).
- Tray frame: pewter serving tray rim; cells are padded soft tiles, **no grid lines** (B-revised). Tiles, lettering and covers code-drawn or hand-set (Playbook stage 5).
- **Mock deltas for ART's final B-revised visuals** (the wide mock and mocks A–C predate v0.3; post-lock follow-up, not a lock blocker): remove the "★ 31" star chip (no stars, D-09); rules line "1 per row · column · patch — never touching" → the D-02 text ("color", not "patch"); tool buttons = Undo, Hint, Reset (the mock's "Mark" mode button and "Clear" are not in v1: tap cycle covers marking; "Clear" = Reset with confirm); re-render with B-revised tiles (no grid lines), the empty mold mark and polished berry v2; portrait mocks must use a ≥352 px board (ART's legibility sheet uses 334 px = 41.75 px cells at 8×8, which fails TT-AC-07).

**Per-cell state matrix (IN):**
| State | Look | Notes |
|---|---|---|
| Empty | soft padded tile: patch fill + pattern | state `EMPTY` |
| Empty mold (player) | empty fluted cake mold, ink outline, ~60% of cell, full opacity | state `MOLD`; distinct from a cake by shape (empty, no filling) and value, not colour alone |
| Empty mold (auto) | same mold at ≤60% of the player mold's alpha | state `MOLD_AUTO`; D-13 |
| Cake | polished berry v2 sprite, ~80% of cell | state `CAKE`; D-03 |
| Given cake (tutorial) | berry v2 on a small plate | cannot be changed |
| Conflict | cherry ring + diagonal hatch + "!" badge (+ 2 px shake once) | never colour alone (ART cell_states_strip) |
| Hint highlight | gold glow on the unit; pulsing ring on target cell(s) | |
| Solved | toasted golden tint on the tray + sage tick, steam puff | |
**Per-screen states:** Board (in-progress, conflict, hint shown, too-small message, solved), Solved card, Chapter end (card reveal, décor drop), All recipes baked, Home (first-time after ch1, streak 0/n, daily done/not done, all chapters done), Recipe Book (locked/unlocked card), Settings, Rewarded modal (ad loading; ad unavailable → hidden), Paused/hidden (no visual, audio off).
**Entity list (art asset gate, stage 3 entry):** tray frame; 9 patch fills + 9 patterns on soft padded tiles; berry v2 cake; plated given cake; empty mold (player + auto alpha); conflict ring/hatch/"!"; hint glow/ring; golden tray + steam puff; coach bubble; 8 recipe cards (+ locked back); 8 décor pieces + counter shelf; backdrop (portrait + wide); icons: home, settings, undo, hint, 🎬 rewarded, reset, sound, music, close, lock, streak (teacup); tutorial pointer hand.

## 11. Cover + store copy *(Profile ref required)*
**Profile ref (tea-and-tarts.md v1):**
- §8 Spec hooks, TT:126: *"Cover: a teapot plus tarts beside a half-solved tray; the title … only; readable at thumbnail size; 3 variants (16:9, 2:3, 1:1) and a 15–20 s silent preview."*
- §5, TT:80-87: floral teapot, jam and lemon tarts, half-solved tray, one [mold] visible; **NOT** coffee/harbour/sea; cream background, berry/lemon tarts, 3–4 bold region colours, grid readable at ~200 px; title is the only text (CG bans other text, badges); test 2–3 variants on CTR (§7 A8, TT:120).
- §5 Tags, TT:89-95: tags per portal; *"Description keywords (since tags can't carry them): 'logic puzzle', 'Queens-style puzzle', 'star battle', 'brain teaser', 'relaxing', 'daily puzzle', 'bakery', 'tea party', 'no timer'"*; don't use "LinkedIn" or "Meowdoku".
- ⚠️ TT:8-11 trademark "Before submit" item: **resolved by rename** (title TBD, SM 2026-10-25). Re-run the catalog/trademark checks on the new title before stage 7; not a spec blocker.

**DECIDED (copy is drafted now; final copy is generated from live tunables at stage 6):**
- Covers: CG mandatory 16:9 1920×1080, 2:3 800×1200, 1:1 800×800, consistent art, no borders, **title is the only text** (title TBD → covers wait for it), plus a 15–20 s silent preview opening on the cover frame (portal/cg-requirements.md §7). 3 concepts for CTR testing: (A) teapot close-up with a small half-solved tray; (B) tray-forward view with 3 golden cakes and one empty mold; (C) cakes on a tray beside a window onto green countryside.
- **Draft portal description** (literal placeholder `{{TITLE}}` until the title is chosen; never the working name):
  > {{TITLE}} is a relaxing **Queens-style logic puzzle** set in a cozy village **bakery** tea room. Place one cake in every row, every column and every color — but no two cakes may touch, not even at the corners, or they'll stick together in the oven! Every tray has exactly one solution you can find with pure logic: no guessing and no timer. Bake your way through 96 levels, earn up to three stars on each, and finish every chapter to collect a new recipe card and a piece of décor for your tea room, then come back for the daily **Bake of the Day** and keep your streak going. Stuck? A friendly hint explains the next step in plain words. A calm brain teaser and daily puzzle for fans of star battle puzzles, sudoku and bakery games.
- **Controls copy (CONTROLS.md):** Tap/click a cell to set an empty mold, tap again to place a cake, tap again to clear. Right-click sets or clears an empty mold (desktop). Undo, Hint and Reset are below the tray on phones and beside it on desktop.
- **Suggested tags (from TT:92-94):** CrazyGames: Puzzle; `logic`, `brain`, `relaxing`, `daily`, `mouse`, `mobile`, `food`, `cute` (skip `cooking`). Poki: Puzzle, Brain, Cozy, Cake, Food, Mouse. GameDistribution: Puzzle; `logic`, `relaxing`, `cake`, `sudoku`, `thinking`. No portal has a `queens` or `bakery` tag, so "Queens-style" and "bakery" live in the description.

## 12. Portal + ads rules
KNOWN (playbook/portal/SM): first download ≤20 MB target (stock engine OK at day 0; slim engine before the Portal kit); 1 click to gameplay; CG caps midgame ads at 1 per 3 min (SDK); never pair a rewarded and a midgame ad between the same two levels; audio muted during ads. **SM ruling: no ads at all before chapter 1 ends; interstitials only at chapter ends; rewarded ads only for hints.**
- **D-19 — DECIDED:** see §3.4. The only midgame slot is **after the chapter-end screen, when the player taps "Next chapter" or "Home"**, from the chapter 1 end onward, and only if session_s ≥300 (U2), ≥180 s since the previous midgame request (game-enforced), and no rewarded ad played since that chapter's 5th board started. Never after a board, never after/before the daily, never in the tutorial. Rewarded: only "🎬 Hint", always opt-in via a confirm modal with equal-size "Watch" / "No thanks" buttons (Poki: 🎬 icon, non-green button); hint granted only on ad success. Rewarded ads are used for hints only; the profile's other proposed rewarded placements are dropped (no fail state, Shahar Q3). Starter `game/ad_policy.gd` (3 rounds / 5 min) is replaced by a chapter-based policy.
- **D-20 — DECIDED (KNOWN from the kickoff brief):** CrazyGames → Poki → GameDistribution. v1 = CrazyGames build only; Poki/GD SDK adapters are OUT.

### 12.1 CrazyGames SDK v3 (via starter `html/head_include.html` `PKD_CG` + `autoload/ads.gd`)
| Call | When |
|---|---|
| `loadingStart` / `loadingStop` | starter glue; `loadingStop` after the PKD intro finishes |
| `gameplayStart` | a board becomes interactive (first one: after the intro), resume from pause/menu/ad/tab show |
| `gameplayStop` | solved card, chapter end, Home/menus/settings, any ad, tab hidden |
| `happytime()` | **chapter complete only** (CG: "sparingly, for real achievements", portal/cg-requirements.md §2), not every board |
| `requestAd('rewarded')` | hint, after the confirm modal |
| `requestAd('midgame')` | chapter-end slot only (D-19) |
| `muteAudio` + settings listener | honoured (CG Full Launch requirement; starter gap) |
| Data module | save (below); fallback localStorage |
| No ad request | before the first `gameplayStart`, or before chapter 1 ends |

### 12.2 Save
Starter `Store` autoload (CG data module on CrazyGames, else localStorage). **Hard-code the key to the literal `"tea_bakery_save_v1"` in `autoload/store.gd`** (the starter derives it from `config/name`, which will change with the title; the key must never change after launch). Saved: settings, solved boards, current board marks (player molds, auto-molds, cakes; undo stack not saved), recipe cards/décor owned, daily history (completed dates), streak, best streak, total bakes, analytics install id. Written debounced 1.0 s after the last change, and immediately on solve, chapter end, settings change, `visibilitychange → hidden` and `pagehide` (TT-AC-49).

### 12.3 Size/perf
≤20 MB first download (slim engine TODO(PIPE/GB)); boot to first interactive board ≤10 s (TT-AC-12); runtime performance per U3 / TT-AC-46; packs as compact JSON (all v1 packs ≈ <100 KB).

### 12.4 Analytics events — **no analytics at launch (Shahar Q2)**; events stay in code as no-op hooks
Common params on every event: `ev_v` (1), `build_id`, `portal` (crazygames|poki|gd|web), `device` (mobile|desktop, from touch + viewport), `orientation`, `install_id` (random UUID, no PII), `session_id`, `session_s` (seconds since session start), `local_date`.
| Event | When | Params |
|---|---|---|
| `chapter_start` | first board of a chapter becomes interactive, first time only (not replays) | `chapter_id` (1–8), `board_size` (first board's N), `boards_in_chapter` (5), `chapters_completed_before` |
| `chapter_complete` | 12th board of the chapter solved, first time only (v1.1; was 5th) | `chapter_id`, `board_size` (largest N in the chapter), `hints_used` (total), `hints_free`, `hints_rewarded`, `duration_s` (active play time across the chapter's 12 boards; excludes ads, pauses, hidden tab), `wall_s` (chapter_start → complete, real time), `sessions` (sessions spanned), `undo_count`, `conflicts_shown` |
| `board_start` | any board becomes interactive | `board_id` (e.g. `c2-b3`, `d-2026-11-05`), `mode` (chapter|daily), `board_size`, `grade`, `is_replay` |
| `board_complete` | board solved | `board_id`, `mode`, `board_size`, `grade`, `duration_s`, `hints_used`, `undo_count`, `is_replay` |
| `hint_used` | hint shown | `board_id`, `kind` (free|rewarded), `technique` (T1–T6 or `fix`) |
| `daily_complete` | daily solved | `local_date`, `board_size`, `duration_s`, `hints_used`, `streak` |
Implementation: `Analytics` autoload with the event calls above wired in at their trigger points, and a **no-op sink in every build**: no network request, no third-party SDK, no storage of events at launch (TT-AC-53). Debug builds (`?qa=1`) still copy each event into a 200-event ring buffer at `PKD_QA.dump().analytics`, so the hooks stay testable. A production sink is post-launch (TT-AC-34..36, §13.3). With no data collected beyond the CG SDK, the CG privacy/T&C-notice requirement (`/workspace/tea-and-tarts/portal/cg-requirements.md` line 66) is **moot for v1**; it returns if a sink is added.

## 13. Acceptance criteria (checkbox list → QA test IDs in `QA_TEST_PLAN.md`)
Device line (no team phone): QA verifies each live build in 390x844 touch emulation and gives QA PASS first; only then does Shahar open the QA-passed live link on his own phone (D0-25/D0-26).
Conventions: P = 390×844 DPR3 touch emulation; W = wide viewports 800×450, 821×462, 907×510, 1280×720, 1280×800 (DPR1, mouse); "dump" = `PKD_QA.dump().game` (debug build, §13.1). Every AC is PASS/FAIL; a missing hook = BLOCKED. Parts that need the real CrazyGames SDK/QA tool are marked **[stage 7, PO]** and are checked on CG's QA tool before submit; the box-verifiable part gates every build.

### 13.0 QA unblock definitions (v0.3, fixed 2026-10-25 ~09:00 Asia/Jerusalem (UTC+2); these are final for lock)
**U1 Streak, "rolling 7 days" (TT-AC-29).** S = set of *bake dates*; a bake date is the date of the daily board completed (the device-local date when that daily was opened, so finishing after midnight counts for the board's date). A date is in S at most once. T = max(device local date today, latest date in S) (moving the clock back never shortens a streak). Count backward from T (from T−1 if T ∉ S: today not yet baked never breaks a streak): each date in S adds 1; a date not in S is a *miss*. A miss is **forgiven** iff the day before it is in S **and** no other forgiven miss in this run lies within the 6 days after it (forgiven misses are ≥7 days apart, i.e. at most 1 forgiven miss in any 7 consecutive dates). Any other miss ends the count. streak = number of bake dates counted; best_streak = max streak ever (never decreases); total_bakes = |S| (never decreases). The "A fresh streak starts today." line shows when a completion leaves streak == 1 and total_bakes before it was ≥1. The daily is not replayable once completed for its date. Reference implementation + the 11 test vectors of §7.1 are in `spec_assert.py` (`streak()`), and must pass there and in GUT.
**U2 "≥5 min session play" (interstitial floor, TT-AC-17).** session_s = wall-clock seconds since the **first `gameplayStart` of the current page load** (the session starts there; reload = new session; includes menus, ads and hidden-tab time). A midgame request is allowed only if session_s ≥ 300 **and** ≥180 s (`min_gap_between_midgame_s`) have passed since the previous midgame request; the game enforces both itself (not only the CG SDK). `session_s` in analytics uses the same clock.
**U3 TT-AC-46 performance (mid-range mobile proxy).** Release build, Chrome, 390×844 DPR3 touch emulation **with CDP CPU throttling 4×**, served locally, after boot: (a) **input latency**: tap → the cell's new state is visible in a rendered frame, p95 ≤100 ms over 50 taps on an 8×8 board; (b) **smoothness**: over a 120 s scripted play (taps, conflict, hint, solve animation, next board), p95 frame interval ≤33.4 ms (≥30 fps) and **0 long tasks >50 ms** except during board transitions; (c) **transitions**: solve card skipped → next board interactive ≤1.0 s, with no single long task >200 ms; (d) **memory**: JS heap + wasm memory after opening 20 boards is ≤ +20 MB over the value after the first board (no leak). Also run unthrottled at 1280×720 as INFO. QA's proposed "no long task >50 ms when opening 10 boards" is replaced by (b)+(c).

### 13.1 QA hooks GB must provide (H1–H6, BR-2, BR-3: debug builds only, absent from release per the release audit; BR-1: release too, allowed by the audit) — adopted from QA §0.4
H1 `PKD_QA.dump().game` schema exactly as listed in `QA_TEST_PLAN.md` §0.4 (screen, board_id, mode, n, regions, cells[], conflicts, solved, undo_len/undo_hash, board_rect, cell_css, ui[] with rect/font CSS px, hint{free_left, rewarded_visible, text, technique, targets, pulse_count}, timer_visible, active_s, streak/best_streak/total_bakes, unlocked, save_key, analytics ring, ads_log, sdk_log, texture_id per region, `too_small` flag, `save_writes[]` with timestamps). H2 `PKD_QA.show("board:c2-b3" | "daily:YYYY-MM-DD" | "solve_next" | "home" | "gen:N,seed")` (solve_next uses the real input path). H3 `?qa=1&date=YYYY-MM-DD&session_offset_s=N`. H4 `?qa=1&ads=mock_available|mock_unavailable|mock_error|mock_timeout` + mock delay ≥0.6 s. H5 `tools/validate_boards.gd`, `tools/seed_sweep.gd` (JSON out, non-zero exit, node budget not wall clock). H6 `CONTROLS.md` + `portal/copy/*.md` in the repo. **Required before the Thin-slice gate.**

**Build requirements (SM-approved v0.3.1; Build treats them as requirements before the Thin-slice gate, like H1–H6):**
- **BR-1 (release builds too, not debug-only): performance marks.** Via `JavaScriptBridge`, call `performance.mark()` with `pkd:transition_start` (solved-card skip / Next tapped), `pkd:transition_end` (next board drawn) and `pkd:board_interactive` (next board accepts input). Each mark also prints one console line in a single parseable format: `pkd:perf <mark> <ms>` (`<ms>` = `performance.now()` at the mark, 1 decimal; e.g. `pkd:perf pkd:board_interactive 18234.6`). Used by TT-AC-46 (b) and (c) to bound transitions and exclude them from the long-task window.
- **BR-2 (debug `?qa=1` only): runtime date + repeat daily.** `PKD_QA.set_date("YYYY-MM-DD")` changes the game's local date at runtime (H3 only sets it at load), firing the same day-change path as a real midnight rollover. `PKD_QA.retry_daily()` forces a second completion attempt on the current date's daily, which must be rejected without changing the streak. Used by TT-AC-29 (vectors V8, V9).
- **BR-3 (debug `?qa=1` only): runtime session clock + midgame decision log.** `PKD_QA.set_session_s(N)` sets session_s at runtime (H3 `session_offset_s` only sets it at load). **Every** midgame-ad decision, allowed or denied, appends `{t, session_s, origin, allowed, reason}` to `PKD_QA.dump().ads_decisions[]`. `reason` is one of `ok`, `session_s<300`, `gap<180s`, `chapter1_not_done`, `not_chapter_end`, `daily`, `replay`, `rewarded_since_b5`, `before_first_gameplayStart`, `ad_unavailable`. Used by TT-AC-17.

### 13.2 Criteria
**Rules / generator / content**
- [ ] **TT-AC-01** A board is "solved" iff N cakes are placed with one per row, column and region and no two 8-adjacent (R1–R4, R6); empty molds are ignored. *GUT on `game/rules.gd` (§4 solution + ≥20 stored solutions true; each single-rule violation, N−1 and N+1 cakes false) + dump `solved`.*
- [ ] **TT-AC-02** Every board in every shipped pack has exactly one solution (solver count == 1, cap 2, node budget 5 000 000), and the independent Python solver (`proto/`) agrees on 100%. *H5 validator + cross-check.*
- [ ] **TT-AC-03** Every shipped board is solved by the §16.3 ladder without T7, and its stored grade equals the recomputed grade (validator 100%; proto grader agrees on the fixed 50-board set). *H5.*
- [ ] **TT-AC-04** Region map valid: N regions, each 4-connected, covering all N² cells; the stored solution has one cake per region and matches `givens`. *H5.*
- [ ] **TT-AC-05** *(QA-scripted tutorial; replaces "first-time tester ≤60 s")* Fresh profile, P touch: (a) intro `finished` → first cake placed ≤15.0 s when the script taps the pulsing target at t+3 s; (b) c1-b1, b2, b3 are each solvable with ≤2 placements; (c) b2 is interactive ≤2.0 s after b1's last cake with no input; (d) the dump `screen` log has no menu/title/map screen between b1 and b2. The human "≤60 s" target is not a gate (§3.3); Growth checks CG conversion ≥80% post-launch (profile §7 A1). *MQ P.*
- [ ] **TT-AC-06** A tap/click cycles empty → mold → cake → empty (cell states `empty`/`mold`/`cake`; with Settings "cake first": empty → cake → mold → empty); one touchstart/touchend per step, taps 450 ms apart; a 600 ms hold acts as one tap; right-click toggles mold↔empty on desktop; a cake can be placed on a mold cell. *MQ P + D; both orders (Q1).*
- [ ] **TT-AC-07** On every screen state at P and at all W viewports, for every board size offered there: every interactive `ui[]` rect ≥44.0×44.0 CSS px; board `cell_css` ≥44.0; min font ≥12.0 CSS px; body text ≥16.0; labels ≥14.0; buttons ≥48.0 tall; OCR x-height agrees with the dump within 15%. At P no board with N ≥9 can be opened (`show("gen:9,1")` refused, none listed). **No exceptions.** *MQ P/W + CG + OCR.*
- [ ] **TT-AC-08** Rule conflicts: 2 cakes in one row, then 2 diagonal neighbours → `conflicts` lists exactly the offending cakes within ≤300 ms; a greyscale screenshot shows the ring + hatch + "!" on each; removing one cake → `conflicts == []`; no counter/penalty field changes. *MQ P.*
- [ ] **TT-AC-09** Progress persists: with solved boards, marks on the current board, settings and (Content stage) streak + cards, a reload and a tab close/reopen made 1.1 s after the last tap restore identical dump fields (undo stack excluded); the only localStorage key used is exactly `tea_bakery_save_v1` (hard-coded, not derived from `config/name`). CG data-module path: **[stage 7, PO]** same check on the CG QA tool. *MQ P.*
- [ ] **TT-AC-10** Daily mapping: two fresh profiles with `date=2026-11-05` get the same `board_id` and regions hash == `pool[3]`; GUT: 2026-11-01 → index 0 (clamp), 2026-11-02 → 0, 2027-12-07 → 0 (wrap at 400); `ci/run.sh` prints a WARN when today + 60 days ≥ the wrap date. *GUT + MQ (H3).*
- [ ] **TT-AC-11** During every mock ad (all 4 modes, delay ≥0.6 s) `mute_reasons` contains "ad" and `PKD_AUDIO.state()` shows audio suspended from request to result; any two midgame requests are ≥180 s apart (game-enforced, U2); `mock_error`/`mock_timeout` grant no hint and leave the button retryable; `mock_available` grants exactly 1 hint. *MQ P + H4.*
- [ ] **TT-AC-12** (a) `navigationStart` → first board interactive ≤10.0 s, median of 3 cold loads (cache disabled) in Chrome headless 1280×720, for the gated build on localhost and for the live URL from the box; (b) first-download bytes (gz transfer of html + js + wasm + pck) ≤20 MB → PASS; >20 MB → WARN (gate packet says "stock engine") until the Portal-kit gate, FAIL from then. *CI gate packet + MQ D + LC.*
- [ ] **TT-AC-13** 0 console errors/warnings/pageerrors outside `ci/console_allowlist.txt` (each line justified) in boot smoke at 390×844, 1280×720, 1280×800, 800×450 (Day-0) and in every MX cell (Thin slice). *CI + MQ/AU/CG.*
- [ ] **TT-AC-14** The gate packet shows the `--live` hash match and the D0-25 touch-emulation PASS, timestamped **before** Shahar's own-phone screenshot (D0-26). QA checks the record; the phone check itself is Shahar's. *CI `--live` + gate packet.*
- [ ] **TT-AC-15** After each of a 30-action sequence (taps, cake removals with auto-molds), Undo restores `cells[]` and `undo_hash` to the exact pre-action dump (30/30); Undo is disabled after solve; Reset shows a confirm: Cancel keeps the board, OK empties every non-given cell. *MQ P.*
**Ads**
- [ ] **TT-AC-16** **No ad of any kind before chapter 1 ends:** a full ch1 run with 3 hints per board shows 0 `midgame`/`rewarded` requests in ads_log and sdk_log until `board_complete c1-b5`; no 🎬 badge appears on any ch1 board (OCR + dump). *MQ P + H2/H4.*
- [ ] **TT-AC-17** **Interstitials only at chapter ends.** Over a scripted run of ch1–ch3 + 2 dailies with `session_offset_s` 0 / 290 / 310: every midgame request has `origin == "chapter_end"`; there are 0 midgame requests (i) with `session_s < 300` (U2), (ii) after any board solve, (iii) before, after or during the daily, (iv) before the first `gameplayStart`, (v) during replays, (vi) after a chapter in which a rewarded ad played since its 5th board started, (vii) within 180 s of the previous midgame request; for each case (i)–(vii), and for edges at session_s 299/300 and gap 179/180 s set at runtime via BR-3 `set_session_s`, `ads_decisions[]` holds one entry per decision with the matching `allowed`/`reason`. *MQ P + H2/H3/H4 + BR-3.*
- [ ] **TT-AC-18** **Rewarded ads only for hints:** every rewarded request has `origin == "hint"`; the confirm modal's "Watch 🎬" and "No thanks" rects differ ≤1 CSS px in width and height; "No thanks" adds 0 ads_log entries and leaves `free_left`/hint state unchanged. *MQ P + H4.*
- [ ] **TT-AC-19** Hint allowance: on chapter-1 boards (first play **and replay**) hints are unlimited and free with no ad; on a ch2+ or daily board hint 1 is free (`free_left` 1→0, no ads_log entry), hint 2 opens the rewarded modal; the next board starts with `free_left == 1` (not banked); with `ads=mock_unavailable` and `mock_error` the 🎬 option is not visible and 0 console errors occur. *MQ P + H4.*
**Hints / board**
- [ ] **TT-AC-20** Hint logic + text: (a) GUT: on the §4 board from empty, 8 consecutive hint+apply calls produce exactly steps 1–8 (technique + target cells); (b) with a wrong cake, or a mold on a solution cell, the hint has `technique == "fix"` and targets that cell; (c) every hint text has exactly one terminal `.`/`!`/`?`, ≤140 characters, and none of: T1–T7, technique, confinement, lookahead, naked, hidden, X-wing, candidate, region. *GUT + MQ P.*
- [ ] **TT-AC-21** No fail state: no `ui[]`/OCR text matches `/lives|life left|mistakes? left|game over|time's up/i` on any screen, and no such field exists in the dump; property test: 200 random tap sequences (length 1–60) on 5 boards, then tapping each non-given cell ≤3 times reaches all-empty, and entering the stored solution then gives `solved == true` (200/200). *MQ P + OCR + GUT.*
- [ ] **TT-AC-22** Auto-mold (default ON): after a cake, every empty cell in its row, column, region and 8-neighbourhood is `mold_auto`, drawn with alpha ≤0.6 × the player mold's; with an overlapping player mold and a second cake, removing cake 1 leaves the player mold and cake 2's auto-molds; toggling the setting off leaves 0 visible `mold_auto`. *MQ P + pixel sample.*
- [ ] **TT-AC-23** Boot routing: fresh profile → screen log = [intro, board c1-b1]; tap, click and key each skip the intro (3 fresh sessions, intro ends <1.93 s); returning player → the board with saved marks if any, else the next unsolved chapter board in order, else (all chapters done) Home; after marks on c1-b4 + reload: boots to c1-b4 with identical `cells[]`. *MQ P + D.*
- [ ] **TT-AC-24** Tutorial c1-b1..b3: exactly 1 coach line each, matching its rule (rows/columns; colors; no touching); tapping a given cell 3× leaves it `given`; each solvable with ≤2 placements. *MQ P + OCR.*
- [ ] **TT-AC-25** Solve flow: after the last cake the bake reward runs ≤1.5 s; with no input the next chapter board is interactive ≤2.0 s after `board_complete`; one tap skips the card in ≤0.3 s; after a chapter's 5th board the chapter-end screen shows instead; after the daily the solved card returns to Home; no "submit/check/done" control exists. *MQ P (timed dumps) + ffmpeg frames.*
- [ ] **TT-AC-26** First completion of chapter N: `unlocked.recipes` and `unlocked.decor` each +1, visible on the chapter-end screen, in the Recipe Book and on the Home shelf; replaying all 12 boards changes neither count and shows no chapter-end screen. *MQ P + H2.*
- [ ] **TT-AC-27** Content: 8 chapters × 12 boards (v1.1) with the §3.5 sizes/grades; daily pool length 400 with size `sizes_mon_to_sun[weekday(epoch + j)]` and grade ≤2 weekday / ≤3 weekend at index j; 0 canonical duplicates across all packs; no shipped board larger than 8×8. *H5 + `spec_assert.py`.*
- [ ] **TT-AC-28** Bake of the Day: Home daily button `enabled == false` before c1-b5 is solved, true after; once completed for a date the button shows "Baked ✓" and the daily for that date cannot be started again; the streak changes at most once per date. *MQ P + H2/H3.*
- [ ] **TT-AC-29** Streak = U1 exactly: GUT with a mocked clock passes all 11 vectors V1–V11 (§7.1) for streak, plus best_streak/total_bakes where listed; in the browser (H3 dates) V3 and V5 reproduce, V5 shows the OCR line "A fresh streak starts today.", and V8 (BR-2 `retry_daily` on a baked date: streak, best and total unchanged) and V9 (BR-2 `set_date` past midnight during play: the board keeps its own date) reproduce at runtime. *GUT + MQ P + BR-2.*
- [ ] **TT-AC-30** No timer during play: `timer_visible == false` and OCR finds no `\d:\d\d` while a board is unsolved; the solved card shows "Baked in m:ss" equal to `active_s` ±1 s; hiding the tab for 10 s does not increase it. *MQ P + OCR.*
**SDK / audio**
- [ ] **TT-AC-31** CG SDK call log (mock): first `gameplayStart` after the intro's `finished`; a `gameplayStop` within 300 ms of each of: solved card, chapter end, Home, Settings, ad start, tab hide; a `gameplayStart` within 300 ms of each return to an interactive board; `happytime` count == chapters completed (0 on board solves). Real SDK: **[stage 7, PO]** same sequence on the CG QA tool. *MQ P + sdk_log.*
- [ ] **TT-AC-32** Mock CG settings event `muteAudio=true` → `PKD_AUDIO` suspended and no audio playing; `false` → restored; in-game Sound and Music toggles change `PKD_AUDIO.state()` immediately and persist (TT-AC-09). Real settings listener: **[stage 7, PO]**. *MQ D + mock.*
**Art / readability**
- [ ] **TT-AC-33** Readability & contrast, on one board of each size 5–9 (9 via H2 `gen:9,seed` in W): every region has a unique `texture_id`; for every pair of adjacent regions ΔE2000 ≥10 between fills under deuteranopia, protanopia and tritanopia (Machado 2009, severity 1.0) and greyscale ΔL* ≥8 or different texture; the cake sprite is the chapter's piece (§10 table; dump `piece`, e.g. `"scone"` on ch1, `"chocolate"` on the daily) and, for **every** shipped piece (v1.2), measured on the @2x pixels along 360 rays: a cream halo (#FFF8EC ±40) 2–6 px inside the outer edge on ≥98% of rays, an ink pixel (#43283A ±60) within 32 px of the edge on ≥94% of rays, and ink ≥3:1 against every patch fill (`tests/test_cake_contrast.gd`). *MQ screenshot + Python colour script + ART palette json.*
- [ ] **TT-AC-38** Inland setting: ART's asset manifest (`docs/art/LICENSES.md`) has no asset tagged coffee/sea/harbour/boat/lighthouse; OCR of all screens, covers and preview frames finds none of those words; ART + Shahar visual sign-off line recorded in the gate packet (**[Content, ART + Shahar]**). *Manifest grep + OCR + sign-off.*
**Analytics (v1: no analytics at launch)**
- [ ] **TT-AC-53** No network analytics at launch: on the release build, over a scripted run (boot → ch1 complete incl. a hint → ch2 b1 → daily) with the CDP network log recording, every request goes only to the game's own origin (html/js/wasm/pck/packs) or CrazyGames SDK/ad domains; 0 requests to any analytics endpoint or third-party analytics SDK; **0 `sendBeacon`/`fetch` from game code** (our GDScript/JS glue; initiator stack outside `crazygames-sdk-v3.js`); any `sendBeacon` must come from the CG SDK and target hosts on `/workspace/tea-and-tarts/portal/CG_NETWORK_ALLOWLIST.md` (e.g. the SDK's own telemetry to `cza.crazygames.com/event` on live CG, which our `data.*` calls can trigger); the `Analytics` sink reports `noop`. *Note (v1.0.2, rule unchanged):* the engine loader's same-origin fetches of the game's own export files (`index.wasm`, `index.pck`, other export files) are allowed; "game code" means our GDScript and JS only. In the debug build the same run still fills `dump().analytics` with the §12.4 events (hooks present). *MQ P + CDP network log + RA.*
**Layout / device**
- [ ] **TT-AC-37** In the wide layout at every W viewport and for every board size 5×5–8×8 (and 9×9 via H2): all interactive `ui[]` rects and `board_rect` lie fully inside the viewport; the board is left and the panel right (board_rect.x < panel.x); `scrollHeight ≤ innerHeight` and `scrollWidth ≤ innerWidth`. In the phone layout at 390×844, 360×640, 412×915, 768×1024: same containment, board above the tool row. *MQ/AU/CG.*
- [ ] **TT-AC-40** With 6 marks and `undo_len == 6`: P → 844×390 → P, then resize to 1280×720: `cells[]`, `undo_len`, `undo_hash` unchanged, board fully on screen each time, layout switches phone ↔ wide. *MQ rotate + AU.*
- [ ] **TT-AC-50** **9×9 on wide viewports:** with `show("gen:9,1")`, `cell_css` ≥44.0 at 800×450, 1280×720 and 1280×800 (expected 45.56 / ≥75 / ≥84 with Art's margins) and every `ui[]` rect ≥44 px; the same board is refused (not opened, too-small message) at 390×844 and 844×390. *MQ W + P.*
- [ ] **TT-AC-52** **No scaled portrait in landscape:** at 800×450 (and 821×462, 907×510, 1280×720) the dump reports `layout == "wide"`, `board_rect.x` < the tool panel's x (board left, recipe card + buttons right), and the board height ≥ 0.85 × viewport height; no screen renders the portrait column scaled into the landscape viewport (portrait `layout` never appears when width > height); and at 800×450 on every screen state every interactive `ui[]` rect is ≥44.0×44.0 CSS px and every text ≥12.0 CSS px (OCR x-height cross-check). *MQ W + CG + OCR.*
- [ ] **TT-AC-48** Too-small message: whenever the current board's cell would be <44 CSS px (e.g. 8×8 at 700×360 landscape; 9×9 at 844×390), within 500 ms of the resize the board is covered by "Turn your device upright or enlarge the window to play this tray.", taps on the board change nothing, and the state is kept; it disappears within 500 ms of a resize that fits again. *MQ resize + dump `too_small`.*
**Save / misc**
- [ ] **TT-AC-41** Corrupt save (`"{not json"` under the key) → 0 page errors, boots to c1-b1, and `tea_bakery_save_v1_corrupt == "{not json"`; GUT does the same natively. *GUT + MQ P.*
- [ ] **TT-AC-49** Save timing: storage reflects a board change ≤1.1 s after the last input (debounce 1.0 s; burst of 10 taps → ≤2 writes); a solve, chapter end, settings change and `visibilitychange → hidden` / `pagehide` each write immediately (the write completes before the handler returns for localStorage; within 300 ms in the CG data-module mock). *MQ P + dump `save_writes[]`.*
- [ ] **TT-AC-42** `spec_assert.py` passes (content sums, chapter times, tutorial range, phone + wide cell math incl. 9×9 at 800×450, banned-name/old-title copy scan, ad/hint tunables, streak vectors). *CI.*
- [ ] **TT-AC-43** Hint strings exist for T1–T6, fix-cake and fix-mold, each ≤140 characters, rendered at ≥16.0 CSS px. *GUT + MQ P.*
- [ ] **TT-AC-44** PKD intro: 3 boots each log `[PKD] intro finished` at 1.7–2.2 s when not skipped; the pck listing contains `pkd_intro/`; `?intro=0&audio=0` disables intro/audio in **both** debug and release (FF bisect toggle, PLAYBOOK D0-16); covers + preview (1 fps frames): 0 frames with normalised correlation ≥0.8 to the PKD logo template and 0 OCR hits for "PKD"/"Pikeydi". *D0 + RA + ffmpeg/OCR.*
- [ ] **TT-AC-45** Determinism: for the 50 fixed (size, seed) pairs in `qa/fixtures/tt_seeds.json`, board JSON sha256 is identical across 2 Godot native headless runs and the web debug build in Chrome (`show("gen:N,seed")`). (Safari/Firefox not testable on the box.) *GUT + MQ.*
**Copy**
- [ ] **TT-AC-39** No old title, no working name and no game name in any user-facing text (one exception: the neutral build placeholder "Bakery Logic Puzzle" in `config/name` and the HTML `<title>` until the title is chosen): 0 case-insensitive hits for the §3.5 `banned_user_text` patterns, i.e. the old title in any spelling (`\btea[\s_-]*(&amp;|&|\+|and|'?n'?)[\s_-]*tarts?\b`: "Tea & Tarts", "Tea and Tarts", "tea&tarts", "Tea-n-Tarts", …), `tea-bakery`, `linkedin`, `meowdoku`, and `\bpop[\s_-]*tarts?\b` ("Pop-Tart(s)", "pop tart"), in the game's string tables, recipe/décor names, CONTROLS.md, `portal/copy/*`, OCR of all screens, covers and preview frames (1 fps). Generic "tart(s)" in recipe/food names (e.g. "Jam tarts") is allowed: the trademark concern applies to the game title, not to recipe names. Portal copy uses the literal placeholder `{{TITLE}}` until the title is chosen; the description contains "Queens-style" and "bakery". Repo paths with the old slug are INFO only. *`tt_title_scan.py` + grep + OCR.*
**Performance / post-game / idle**
- [ ] **TT-AC-46** Performance = §13.0 U3 (a)–(d), all four; (b) and (c) delimit transitions using the BR-1 marks `pkd:transition_start`/`pkd:transition_end`/`pkd:board_interactive` (trace marks or `pkd:perf <mark> <ms>` console lines; a release build missing them = FAIL). *MQ P with CDP CPU throttle 4× + Performance trace + BR-1.*
- [ ] **TT-AC-47** Idle hint pulse: on an unsolved board with the Hint button visible, after 30.0 s (±0.5 s) without input the Hint button pulses once (`hint.pulse_count` 0→1); no hint is consumed, no ad requested; it never pulses twice on the same board, and any input before 30 s resets the timer. *MQ P (timed).*
- [ ] **TT-AC-51** After chapter 8 (§7.2): the ch8 chapter-end screen is followed once by "All recipes baked" (8 cards + full shelf + one "Home" button); later boots go to Home, whose primary button is Bake of the Day (or "Baked ✓"), with "Levels" (level map) listing all 96 levels; replays fire no chapter events, unlock nothing, and request no midgame. *MQ P + H2.*
**Structure (v1.1)**
- [ ] **TT-AC-54** Content: 8 chapters × 12 boards = 96 chapter boards; every one unique, solved by the §16.3 ladder with the stored grade, sizes/grades == §3.5 tunables, all distinct from each other and from the daily pool; b1–b5 of every chapter are byte-identical to v1.0.2 (pinned by pack source id). *GUT `test_chapters.gd` + H5.*
- [ ] **TT-AC-55** Stars: a clean solve (no hint, no conflict) shows 3 filled stars on the solved card and stores 3; a solve with a conflict and no hint stores 2; any hint (incl. "Show me") gives 1; a replay never lowers the stored best; a v1.0.x save loads with 1 star per solved board; nothing on screen shows a running timer (TT-AC-30 unchanged). *GUT `test_stars.gd` + MQ P.*
- [ ] **TT-AC-56** Level map: shows 96 numbered level buttons (8 chapter groups × 12) with best stars; solved levels replay, the first unsolved level plays (primary button), every later level is locked and refuses to open; the board title reads "Level N" with N = (chapter − 1) × 12 + board; Home shows "Levels" once a level is solved and "Stars: x / 288". All buttons ≥44 px (TT-AC-07). *GUT `test_end_state.gd` + MQ P layout.*
**Count: 56 ACs: 53 gating v1 (TT-AC-01..33, 37..56) + 3 post-launch (TT-AC-34..36, §13.3).**

### 13.3 Post-launch ACs (NOT gating v1; apply only when an analytics sink is added after launch)
- [ ] **TT-AC-34** `chapter_start` fires exactly once per chapter_id on first play, at its b1 `board_start`, with `chapter_id`, `board_size`, `boards_in_chapter == 12` (v1.1), `chapters_completed_before` + all common params; 0 on replay. *MQ P + dump analytics.*
- [ ] **TT-AC-35** `chapter_complete` fires exactly once per chapter (first time) on its 12th solve (v1.1) with `chapter_id`, `board_size`, `hints_used == hints_free + hints_rewarded`, `duration_s` within ±2 s of Σ the 12 `board_complete.duration_s` (a 20 s hidden tab and a mock ad add nothing), `wall_s`, `sessions`, `undo_count`, `conflicts_shown` + common params; replays fire neither chapter event. *MQ P + H2/H4.*
- [ ] **TT-AC-36** `board_start`, `board_complete`, `hint_used`, `daily_complete` carry exactly the §12.4 keys + common params (no extra keys); `board_*` on replays carry `is_replay == true`; `install_id`/`session_id` match UUIDv4; no value matches email, IPv4/IPv6, user-agent or URL patterns. Applies once a production sink exists. *MQ P.*


## 14. QA questions and rulings (QA review `QA_TEST_PLAN.md` §0; answered in writing before Build)
GD seed answers from v0.2 stand (auto-clear only for auto-molds; molds ignored for "solved"; no losing; hint fix-first; daily at local midnight; ads via the starter mock; analytics via the dump ring buffer).
**§0.1 Contradictions**
| QA item | Ruling |
|---|---|
| 0.1.1 "Tarts" in content | **"Jam tarts" stays** (TT Studio Manager ruling): the trademark concern applies to the game title, not to recipe names. TT-AC-39 is narrowed to the old title in any spelling/casing ("Tea & Tarts", "Tea and Tarts", …), "tea-bakery" in player-facing text, LinkedIn, Meowdoku and "Pop-Tart(s)"/"pop tart"; generic "tart(s)" in recipe/food names is allowed. D-03 no longer says "tart-style". `spec_assert.py` applies the same list to recipe/décor names and the spec's player-facing copy. |
| 0.1.2 DAY0.md says "Tea & Tarts" | Agreed; DAY0.md is Pipeline Ops' file → TODO(PIPE/SM): D0-06 `config/name="Bakery Logic Puzzle"` and D0-11 page title "Bakery Logic Puzzle" (neutral placeholder until the title, SM v0.3.1). Not edited by GD. |
| 0.1.3 CI old-title grep too weak | Agreed → TODO(GB): `ci/run.sh` step 7 uses the TT-AC-39 pattern list (= `tt_title_scan.py`). |
| 0.1.4 1280×800 vs 1280×720 | Both, everywhere (TT-AC-13, -37, -50; MX-09/10). |
| 0.1.5 Tutorial 40 s vs ≤60 s | `tutorial_board_s` = {min 20, est 40, max 60}: 40 = estimate for content sums, 60 = design ceiling; QA gates only the scripted TT-AC-05. |
| 0.1.6 Save key | Hard-coded literal `tea_bakery_save_v1` in `autoload/store.gd` (TODO(GB)); TT-AC-09 tests it. |
| 0.1.7 Midgame cap ownership | Agreed: the game enforces ≥180 s between midgame requests itself (U2, TT-AC-11/17). |
| 0.1.8 No 44/12 px lint | Agreed: TT-AC-07 is measured from the dump `ui[]` (H1) + OCR, not a lint. |
| 0.1.9 `?intro=0` scope | Playbook wins: `?intro=0&audio=0` work in **release and debug** (D0-16 bisect toggle); only `?qa=1` hooks are debug-only (TT-AC-44). |
**§0.2 Ambiguities (one-line decision each)**
| QA item | Decision |
|---|---|
| 0.2.1 Thin-slice scope | QA's default accepted: ch1 (incl. tutorial) + ch2, hints (free + rewarded), ads mock, save, SDK lifecycle, analytics, phone + wide layouts. Daily/streak/recipes/décor/full packs = Content stage. |
| 0.2.2 "≥5 min session play" | Wall clock since the first `gameplayStart` of the page load (U2); not active time. |
| 0.2.3 Rolling 7 days | Defined in U1 (§13.0) with vectors V1–V11 (§7.1); forgiven misses ≥7 days apart. |
| 0.2.4 Current vs next unsolved | Board with saved marks if any, else next unsolved chapter board in order, else Home (TT-AC-23). |
| 0.2.5 After b5 / after daily | b5 → chapter-end screen; daily → solved card → Home (TT-AC-25). |
| 0.2.6 After chapter 8 | "All recipes baked" screen once, then Home with Bake of the Day + Replay a chapter (v1.1: Levels); no new content (§7.2, TT-AC-51). |
| 0.2.7 Ch1 hints on replay | Hint rules follow the board: ch1 boards are always unlimited and free with no ad, also on replay; ch2+ replays get 1 free/board then rewarded (TT-AC-19). |
| 0.2.8 Does "tea-bakery" count as a name? | Yes: no title-like string in copy/covers; portal copy uses the literal `{{TITLE}}` placeholder (TT-AC-39). |
| 0.2.9 AC-17 lists | Merged into one exhaustive list (i)–(vii) in TT-AC-17. |
| 0.2.10 Labels ≥14 / buttons ≥48 | Now gating, in TT-AC-07. |
**§0.3 rewordings:** QA's versions adopted for 05, 07, 11, 12, 17, 20, 21, 23, 25, 29, 33, 36, 37, 38, 44, 45, with these GD changes: 05 drops the "05b" human/conversion part as a gate (it's a Growth post-launch check); 20 adds `!`/`?` as terminal marks and keeps the "region" ban (UI says "color"); 21 bans "time's up" instead of "time" (the solved card legitimately says "Baked in m:ss"); 33 adds the berry-v2 contrast check; 37 also covers the phone layout and board-left/panel-right in wide; 09/31/32 real-SDK halves are tagged **[stage 7, PO]** instead of left unverifiable.
**§0.4 hooks:** H1–H6 adopted as GB requirements (§13.1). Reduced-motion: **OUT of v1** (no AC). Settings "Reset progress" confirm and toggles reachability stay QA additions (QA-A04). Daily midnight / clock change / epoch and wrap: covered by V9, V10 and TT-AC-10. Replay `is_replay`: TT-AC-36. Performance: TT-AC-46 (U3), adjusted from QA's proposal (see U3).

## 15. Cut line (IN / OUT) + Rulings
**IN (v1 = first on CrazyGames):** (v1.2) one cake per chapter + chocolate daily cake (§10); (v1.1) level map with 96 numbered levels, sequential unlock, 1–3 stars per level (§3.6/§3.7); PKD intro → ch1 b1 (no menu); rules R1–R8; tap cycle (empty → mold → cake) + right-click mold + tap-order setting; auto-mold (toggle); undo/reset; live conflict highlight; hints (next-deduction + plain-words text; free in ch1, 1 free/board after, rewarded after); generator + validator + grader (offline, GDScript headless) with the unique-solution guarantee; 96 chapter boards (5×5–8×8, v1.1) + 400-board daily pool; 3 tutorial trays; Bake of the Day + gentle streak; 1 recipe card + 1 décor piece per chapter (Recipe Book + counter shelf); Home, Settings; save/resume; CG SDK (gameplay start/stop, rewarded hints, chapter-end midgame, happytime on chapter complete, muteAudio, data save); analytics events (§12.4) as no-op hooks (no network) with a debug QA ring buffer; phone layout (portrait) + wide layout (all landscape/desktop, every board size); 44 px targets, ≥16 px body text; region textures for colour-blind players; sound + music + mute.
**OUT (post-v1):** 9×9 "Master trays" content (layout ready on wide viewports, TT-AC-50) · drag-to-paint molds · keyboard controls · runtime/endless generation (D-21) · best times, leaderboards (stars are IN since v1.1, §3.6) · solution "check" toggle · lives / fail state · any currency or shop · per-region pastry sprites (per-chapter cakes are IN since v1.2) · décor placement/customisation · more chapters · more than 1 daily board · localisation (JA/PT-BR per §7 A7) · Poki/GD SDK adapters · `reportGameCompletedPercentage` · achievements · reduced-motion mode · analytics production sink + TT-AC-34..36 (post-launch, Shahar Q2).
**Rulings addendum (2026-10-25, broadcast per standing rule 7):**
- R-01 Player Profile v1 is final for spec lock (CoS; PLAYBOOK.md:63; CHANGELOG v1.3).
- R-02 Phones max 8×8; 9×9 allowed on wide (desktop/landscape) viewports incl. the 800×450 CG embed (45.56 px cells, Art wide layout); 44 px rule has no exceptions (SM, D-04, updated v0.3). v1 ships no 9×9 content.
- R-03 Ads: none before chapter 1 ends; interstitials only at chapter ends; rewarded only for hints (SM).
- R-04 Title "Tea & Tarts" dropped (Pop-Tarts risk); working name tea-bakery; Title TBD; paths keep the old slug until rename (SM). Trademark item resolved by rename; not a spec blocker.
- R-06 Wide layout (board left at full height, card + buttons right) for every board size on desktop/landscape, as a real re-layout, never a scaled portrait (TT-AC-52); phones keep the portrait column (SM, v0.3).
- R-07 Berry v2 is the shipped piece (ART + SM, v0.3).
- R-08 Ch4 card "Jam tarts" stays (SM); TT-AC-39 bans the old title in any spelling, the working name, LinkedIn, Meowdoku and "Pop-Tart", not generic "tart(s)" (v0.3, QA §0.1.1).
- R-09 `?intro=0&audio=0` work in release too (Playbook D0-16; QA §0.1.9).
- R-05 No fail state and no lives (Shahar Q3); rewarded ads are for hints only. Growth aligns profile v2 with this ruling.
- R-10 v1.0 (Shahar via SM/CoS): Art style "B-revised" (final visuals = Art deliverable, Shahar OK); mark = empty cake mold, mold-first tap order; no analytics at launch (no-op hooks); no fail state.

## 16. Puzzle generation + validation
All shipped boards are **pre-generated offline**, validated headless, and committed as JSON packs (Playbook stage 4).
- **D-21 — DECIDED:** no runtime generation in v1; endless mode OUT. *Rationale:* the curated pack guarantees grade, ramp and uniqueness; prototype timings show 9×9 repair takes ~3 s/board in Python (much slower in GDScript on web).
- **D-22 — DECIDED: GDScript headless** (`godot --headless -s tools/gen_packs.gd`), building on GB's `game/generator.gd`, `game/solver.gd`, `game/tt_rng.gd`. *Rationale:* one codebase, and the §16.3 grader is needed at runtime anyway for hints (TT-AC-20). The Python prototype (`proto/`) is a cross-check only: a CI test asserts both agree on solution count and grade for a fixed 50-board set.

Prototype evidence (Python, `proto/gen.py` + `proto/repair.py`, 2026-10-25): plain random regions give unique boards for 27% of 5×5 tries but ~0% at 8–9; with the §16.2 repair step, 30 unique boards per size took 0.1 s (6×6), 0.5 s (7×7), 6.4 s (8×8), 96 s (9×9), with 8–27% needing lookahead beyond the ladder (rejected/regraded). Offline generation of 440 boards is cheap (v1.1 ships 496: 96 chapter + 400 daily).

### 16.1 Board format
```json
{"id":"c1-b3","size":6,"regions":["AABBBC","ADDBCC","..."],"solution":[1,3,5,0,2,4],
 "grade":2,"techniques":["T1","T3","T4"],"steps":14,"seed":123456,"gen":"ttgen-0.1",
 "givens":[]}
```
`solution[r]` = cake column in row r; `givens` = pre-placed cells (tutorial only). Packs: `game/levels/chapter_NN.json`, `game/levels/daily_pool.json` (ordered; index = day offset from the epoch; weekday sizes per §3.5).

### 16.2 Generator
1. Solution: a permutation `c[0..N-1]` with `|c[r] − c[r+1]| ≥ 2`.
2. Grow N regions from the N cakes by randomised 4-connected frontier growth; region size 2..2N (1-cell regions only in G1 / tutorial).
3. Count solutions with the exact solver (stop at 2).
4. If >1: move a cell of the other solution (not a planted cake) into a neighbouring region, keeping regions connected; re-count; after K tries regrow (GB's generator already does this).
5. Grade (16.3); keep only boards in the requested grade; dedupe by canonical form (8 symmetries + region relabel). Tutorial trays are hand-made and validated the same way (with `givens`).

### 16.3 Difficulty grading (technique ladder; also the hint engine) — DECIDED
Applied easiest first on the current candidate state; grade = hardest technique needed.
| ID | Technique | Plain-words hint template | Grade |
|---|---|---|---|
| T1 | Last spot: a row/column/region with one free cell → cake | "Row 4 has one free cell left, so its cake goes here." | G1 |
| T2 | After a cake: mold its row, column, region and 8 neighbours (auto-mold) | "Cakes can't share a row, column or color or touch, so set empty molds here." | G1 |
| T3 | Confinement: a region within one row/column → mold the rest of that line (and a line within one region → mold the rest of that region) | "All of butter is in column E, so set empty molds on the rest of column E." | G2 |
| T4 | Shared neighbour: a cell that touches every free cell of some row/column/region → mold | "Whichever cell gets pistachio's cake would touch this cell, so set an empty mold on it." | G2 |
| T5 | Sets: k regions confined to k rows/columns → mold other cells in those lines (k = 2, 3) | "Strawberry and butter fit only in rows 2–3, so set empty molds on the rest of rows 2–3." | G3 |
| T6 | One-step lookahead: a cake here would leave some row/column/region with no free cell → mold | "A cake here would leave row 6 with nowhere to go, so set an empty mold on it." | G4 |
| T7 | Deeper trial / guessing | — | **reject** |
`fix` (not a technique): "This cake doesn't fit the recipe, so let's lift it." / "This empty mold hides a cake spot, so let's clear it."
Grade bands per chapter: §3.2. Grade 4 appears at most once per chapter (ch8 b4 only in v1).

### 16.4 Validator (`tools/validate_boards`, run in `ci/run.sh`; non-zero exit on any failure)
Per board: schema; N×N with N regions; regions 4-connected, cover every cell; stored solution satisfies R1–R4 and matches `givens`; exact count == 1; recomputed grade == stored grade; no T7; no canonical duplicates across all packs; chapter sizes/grades == §3.5; daily pool size == 400 with weekday sizes/grade caps. Writes counts per size/grade into the gate packet.

### 16.5 Board sizes summary
5×5 tutorial/easy · 6×6 · 7×7 · 8×8 (phone max, 44.75 px) · 9×9 wide layout only (45.56 px at 800×450), no v1 content.

---

## Decisions D-01..D-22 (v1.0 status: all closed)
| ID | Decision | Status |
|---|---|---|
| D-01 | 1 recipe card + 1 décor per chapter; Recipe Book + counter shelf; no currency/energy | DECIDED |
| D-02 | "One cake in every row, column and color." / "Cakes can't touch — not even corners — or they'll stick in the oven!" | DECIDED |
| D-03 | UI word "cake"; one cake per chapter (its recipe card), chocolate on the daily, berry v2 on debug boards (§10) | DECIDED (v1.2; was one sprite) |
| D-04 | Phones max 8×8; 9×9 OK on wide (desktop/landscape, incl. 800×450 at 45.56 px); v1 ships no 9×9 content; 44 px AC without exceptions | KNOWN (SM, updated v0.3) |
| D-05 | 8×12 = 96 chapter boards (levels 1–96, level map §3.7) + 400 daily pool; after ch8: §7.2 | DECIDED (v1.1; was 8×5) |
| D-06 | Ramp + grades per §3.2; breather after hard; G4 once (ch8) | DECIDED |
| D-07 | Next-deduction hint with plain words + "Show me"; fix-first; ch1 free; 1 free/board; rewarded after | DECIDED |
| D-08 | No fail state, no lives | KNOWN (Shahar Q3) |
| D-09 | No currency or coins; stars = 1–3 per level as a mastery mark only (§3.6), never spent, never time-based | DECIDED (v1.1; was "no stars") |
| D-10 | Live conflict highlight, not colour alone, no penalty | DECIDED |
| D-11 | Daily rolls over at device local midnight; global by calendar date | DECIDED |
| D-12 | Mold-first tap cycle (empty → mold → cake) + right-click mold + "cake first" setting; drag OUT | KNOWN (Shahar Q1) |
| D-13 | Auto-mold ON by default, toggle | DECIDED |
| D-14 | No menu before board 1 | DECIDED |
| D-15 | 1 daily, same for everyone | DECIDED |
| D-16 | No timer during play; solve time on solved card only | DECIDED |
| D-17 | Art style = "B-revised": style B + soft padded tiles (no grid lines) + empty cake mold mark + polished berry v2 cakes (§10); final visuals = Art deliverable, Shahar OKs; not a spec blocker | KNOWN (Shahar, 2026-10-25) |
| D-18 | UI says "color region", not "dough patch" | DECIDED |
| D-19 | Midgame only at chapter-end slot from ch1 end; rewarded only for hints | DECIDED (SM rules) |
| D-20 | CG → Poki → GD; v1 = CG only | KNOWN |
| D-21 | No runtime generation in v1 | DECIDED |
| D-22 | GDScript headless generator; Python proto as cross-check | DECIDED |

## Questions only Shahar can answer
None open. Answered 2026-10-25 (Shahar, relayed by TT Studio Manager via CoS):
- **Q1 Tap order → mold first:** empty → empty cake mold → cake → empty; the "cake first" setting stays (D-12).
- **Q2 Analytics → none at launch:** events are no-op hooks; post-launch ACs in §13.3; gating TT-AC-53 (§12.4).
- **Q3 Fail state → none:** no lives, no fail state (R8, D-08).
- **Art → "B-revised"** (D-17, §10). Title: stays `{{TITLE}}` in portal copy and "Bakery Logic Puzzle" in config/name until Shahar picks it.

## Lock checklist (Playbook v1.3, stage 1 exit) — v1.0 LOCKED 2026-10-25
- [x] Player Profile exists and v1 counts as final for spec lock (PLAYBOOK.md:63; CHANGELOG v1.3, CoS 2026-10-25); §6, §7, §10, §11 Profile refs checked against v1 line numbers.
- [x] Art, Cover, Onboarding and Session-length sections each cite the profile (section + version + line).
- [x] D-01..D-22 all answered (KNOWN/DECIDED); Shahar Q1–Q3 + Art style answered.
- [x] Worked example (§4) generated, traced and checked by the prototype exact solver (GDScript re-check → follow-up).
- [x] Economy/content assert: `spec_assert.py` passes.
- [x] Every on-screen rule has an AC (R1–R8 → §2 table); 53 ACs numbered and binary (50 gating, 3 post-launch).
- [x] Cut line (IN/OUT) + Rulings present (§15).
- [x] QA spec review answered in writing (§14); `QA_TEST_PLAN.md` drafted by QA.
- [x] QA hooks H1–H6 and build requirements BR-1..BR-3 specified (§13.1) (implementation → follow-up, before Thin-slice).
- [x] Art direction locked as "B-revised"; approved for production as B2 (v1.0.2).
- [x] Portal rules in the spec (≤20 MB, ads, 1-click to gameplay) (§12).
- [x] Title handling fixed for build and copy (`{{TITLE}}`, "Bakery Logic Puzzle"); the title choice itself does not block rules/code.
- [x] Version → v1.0, status LOCKED, changelog with recipients.

## Post-lock follow-ups (non-blocking)
- ~~**GB:** GDScript validator re-check of the §4 worked example~~ **DONE (v1.0.2):** fixture `tests/test_spec_example.gd` (commit 658479f), grade 2, 8 steps. Still open: validator re-check of all packs (TT-AC-02/03).
- **GB:** implement hooks H1–H6 and BR-1..BR-3 before the Thin-slice gate; hard-code the save key `tea_bakery_save_v1` in `autoload/store.gd`; `ci/run.sh` step 7 uses the TT-AC-39 pattern list; analytics sink = no-op (TT-AC-53).
- ~~**ART:** final B-revised visuals → Shahar OK~~ **CLOSED (v1.0.2):** approved as B2 (`art/*_B2.png`, `docs/art/STYLE_GUIDE.md`); keep the cake ink outline ≥3:1 on every patch (berry v2 halo alone is <3:1 on cocoa 2.84 and blueberry 2.57) as a TT-AC check.
- **QA:** re-map test IDs to v1.0 (TT-AC-46..53; TT-AC-34..36 now post-launch; X → mold renames in AC-01/06/15/20/22/43).
- **PIPE/SM:** DAY0.md: drop the old title; D0-06 `config/name` and D0-11 page title = "Bakery Logic Puzzle".
- **Growth:** Player Profile v2 aligned with the v1.0 rulings (mold mark, no fail state, no analytics at launch).
- **ART (v1.2, non-blocking):** add the ink outline to the strawberry on `cake_victoria` and to the macaron feet on `cake_macaron` (ink coverage 0.95 each, the lowest of the 9; halo is complete on both).
- **Shahar → title (the only open item)**, then: one rename pass (paths/slugs), `{{TITLE}}` filled in portal copy, covers, config/name, and a catalog/trademark check on the new title before stage 7.
