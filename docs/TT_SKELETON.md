# tea-bakery (game #4, working name): Day-0 skeleton + generator notes (Godot Build, 2026-10-25)

Working name `tea-bakery` (SM 10-25: previous title dropped for trademark risk; final title + repo name TBD).
The local folder stays `/workspace/tea-and-tarts` because teammates reference paths in it.

## Spec source
Canonical: `/workspace/pipeline-ops/games/tea-and-tarts/SPEC.md` v0.1 **DRAFT, not locked** (GD). Followed where it speaks:
rules R1-R7 and on-screen wording (§2), board 1 = the §4 worked example as a tutorial board with no menu before it (§6),
sizes 5-8 on mobile, 9x9 desktop only (§9 D-04 + SM ruling 10-25), generator method §16.2, live conflict highlight (§5 D-10 option A).

## Assumptions / not yet per spec (to confirm with GD)
1. Difficulty = size for now (`Gen.SIZES`); §16.3 technique-ladder grading (T1-T6, no-guess guarantee, TT-AC-03) not implemented. Solver nodes logged as a stand-in.
2. Runtime generation is used for "New tray"; §16 proposes offline JSON packs + validator (D-21/D-22 open). The GDScript generator/solver can be the validator either way.
3. Patches: 4-connected, any size >=1; no target size spread / canonical dedupe yet (§16.2 step 5).
4. Tap cycle empty → X → cake → empty. No drag-paint X (D-12), auto-X (D-13), undo (TT-AC-15), hints, hearts, timer, save, chapters, daily yet.
5. Win = N cakes, no conflict (R6). X marks never validated (R7).
6. Release: board 1 tutorial then time-seeded boards. `seed`/`size`/`state` URL flags are QA-only (debug, `?qa=1`). Daily seed: D-11/D-15 open.
7. Desktop 9x9 only when the board leaves >= 44 px cells (1280x800: yes; CG 800x450 embed: hidden).
8. Placeholder code-drawn art/palette; landscape backdrop hook at `res://assets/backdrop/` (ART), flat fill until then.
9. CrazyGames: `loadingStop` after the intro (starter), `gameplayStart` once when board 1 is playable (PKD_CG no-ops without the SDK). `gameplayStop` on menus/ads: not wired yet (no menus/ads yet).

## Generator (game/generator.gd)
Own xorshift32 RNG (`game/tt_rng.gd`), seeded with `board_seed(n, seed)`; no global `randi()`.
Placement → patch growth from the n cakes → solver count (limit 2) → reshape (move a non-planted cake cell of the other
solution into a neighbouring patch, keeping patches connected) → after n*n reshapes, regrow. Deterministic per (n, seed).

## QA hooks (debug build)
`?qa=1&seed=<int|text>&size=5..9&state=solved|almost|conflict&intro=0` (seed/size skip the tutorial; size capped by device)
`PKD_QA.dump()` → `game`: n, seed, regions, cakes, marks, conflicts, won, moves, board_rect, gen_ms.
`PKD_QA.show("solve" | "clear" | "new" | "tap:r,c")`.

## Tests
`godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit` (TT_SEEDS=N overrides the default 200 seeds/size).
Game smoke (debug build served): `ci/game_smoke.py <url> <out>` (also step 6 of ci/run.sh).
Benchmark: `godot --headless --path . -s tools/bench_generator.gd -- 200`.
