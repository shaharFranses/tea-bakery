# Tea & Tarts: Day-0 skeleton + generator notes (TT Godot Build, 2026-10-25)

## Spec source
No TT Game Design spec existed on the box at build time (searched /workspace, /home/box/agent-data, /cursor/stores for
`tea.?&?.?tarts|bakery logic`; `/workspace/pipeline-ops/games/tea-and-tarts/` and `/workspace/audience/tea-and-tarts.md` did not exist).
Used: `/workspace/audience/game4-themes.md` (Growth: theme, title, mapping "board = baking tray, region = dough patch"),
the TT Game Design brief (5x5 → 9x9 progression, 1-2 min boards, calm/no time pressure) and GD's in-progress prototype
`spec/proto/gen.py` (not committed here; GD owns it). **Replace these defaults when the spec locks.**

## Assumptions (to confirm with GD)
1. Sizes 5..9; difficulty = size for now: easy 5, medium 6, hard 7, expert 8, master 9 (`Gen.SIZES`).
   GD's tier grader (T1-T4 human deductions, `spec/proto/gen.py`) should replace/augment this; solver node count is logged as a stand-in.
2. Uniqueness: exactly one solution, verified by backtracking (stop at 2). No "solvable without guessing" guarantee yet.
3. Patches are 4-connected, any shape, any size ≥1.
4. Tap cycle empty → X → tart → empty. No drag-to-mark, no undo, no hints, no mistakes counter, no timer yet.
5. Win = n tarts with no conflict (equivalent to the unique solution). Conflicts are highlighted immediately (red).
6. Release boots to a fresh time-seeded 5x5 board after the intro; `seed`/`size`/`state` URL flags are QA-only (debug build, `?qa=1`).
   A shareable/daily seed in release ("Bake of the Day") needs a spec decision.
7. 9x9 at 390 px wide gives ~40 px cells (< 44 px tap target). Needs an ART/GD ruling (bigger board area, zoom, or cap phone at 8x8).
8. Placeholder code-drawn art and palette (not CVD-checked). ART owns the final look.

## Generator (game/generator.gd)
Own xorshift32 RNG (`game/tt_rng.gd`), seeded with `board_seed(n, seed)`; no global `randi()`.
Placement → patch growth from the n cakes → solver count (limit 2) → reshape (move a non-planted cake cell of the other
solution into a neighbouring patch, keeping patches connected) → after n*n reshapes, regrow. Deterministic per (n, seed).

## QA hooks (debug build)
`?qa=1&seed=<int|text>&size=5..9&state=solved|almost|conflict&intro=0`
`PKD_QA.dump()` → `game`: n, seed, regions, cakes, marks, conflicts, won, moves, board_rect, gen_ms.
`PKD_QA.show("solve" | "clear" | "new" | "tap:r,c")`.

## Tests
`godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit` (TT_SEEDS=N overrides the default 200 seeds/size).
Benchmark: `godot --headless --path . -s tools/bench_generator.gd -- 200`.
