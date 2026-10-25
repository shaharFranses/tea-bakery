## tea-bakery puzzle generator: deterministic for (size, seed).
##  1. random valid cake placement (one per row/col, no touching), from our own seeded RNG (tt_rng.gd);
##  2. grow n dough patches out from the n cakes (random frontier growth, 4-connected);
##  3. solver counts solutions (stop at 2). While not unique: take the other solution, move one of its cake
##     cells that is not a planted cake into a neighbouring patch (keeping patches connected). That breaks the
##     other solution and keeps the planted one valid. After n*n reshapes, regrow the patches.
## Difficulty = board size for now (see SIZES); solver nodes are recorded as a secondary grade.
extends RefCounted

const TtRng = preload("res://game/tt_rng.gd")
const Rules = preload("res://game/rules.gd")
const Solver = preload("res://game/solver.gd")

const Cfg = preload("res://game/tt_config.gd")
const GEN_VERSION := "ttgen-0.2"
const SIZES := Cfg.DIFFICULTY_SIZES
const MIN_N := Cfg.MIN_N
const MAX_N := Cfg.MAX_N                # 9x9 desktop only (SPEC §9 D-04 / SM 10-25)
const MAX_N_MOBILE := Cfg.MAX_N_MOBILE  # 358 px board / 8 = 44.75 px cells at 390x844

## Tutorial / board 1 (SPEC §4 worked example, validated unique by the solver in tests/test_puzzle.gd).
const TUTORIAL := {"n": 5, "rows": ["AAACC", "BBACC", "DDACC", "DDDCC", "DDEEC"], "solution": [2, 0, 4, 1, 3]}

static func tutorial() -> Dictionary:
	var n: int = TUTORIAL.n
	var reg := PackedInt32Array()
	for row in TUTORIAL.rows:
		for ch in row: reg.append(ch.unicode_at(0) - 65)
	return {"n": n, "seed": -1, "regions": reg, "solution": PackedInt32Array(TUTORIAL.solution),
		"regrows": 0, "reshapes": 0, "nodes": 0, "ms": 0.0, "tutorial": true}
const MAX_REGROWS := 200

static func difficulty_size(name: String) -> int:
	return SIZES.get(name, 5)

## Mix size into the seed so size 5 / seed 1 and size 6 / seed 1 are unrelated boards.
static func board_seed(n: int, seed_value: int) -> int:
	return (seed_value * 1000003 + n * 7919) & 0x7FFFFFFFFFFF

## Seed from a URL / user string: an int if it parses, else a stable djb2 hash (not String.hash()).
static func seed_from_string(s: String) -> int:
	if s.is_valid_int(): return s.to_int()
	var h := 5381
	for ch in s.to_utf8_buffer(): h = ((h * 33) ^ ch) & 0xFFFFFFFF
	return h

## Returns {n, seed, regions: PackedInt32Array, solution: PackedInt32Array (col per row), regrows, reshapes, nodes, ms}.
static func generate(n: int, seed_value: int) -> Dictionary:
	n = clampi(n, MIN_N, MAX_N)
	var t0 := Time.get_ticks_usec()
	var rng = TtRng.new(board_seed(n, seed_value))
	var solver = Solver.new()
	var reshapes := 0
	for regrow in MAX_REGROWS:
		var sol := _placement(n, rng)
		var reg := _grow(n, sol, rng)
		var planted := {}
		for r in n: planted[r * n + sol[r]] = true
		for step in n * n:   # reshape budget per growth (bench: 1x n*n beats 2x and 6x on 9x9 p95)
			var sols: Array = solver.solve(n, reg, 2)
			if sols.size() == 1:
				return {"n": n, "seed": seed_value, "regions": reg, "solution": sol, "regrows": regrow,
					"reshapes": reshapes, "nodes": solver.nodes, "ms": (Time.get_ticks_usec() - t0) / 1000.0}
			var alt: PackedInt32Array = sols[0] if sols[0] != sol else sols[1]
			if not _reshape(n, reg, alt, planted, rng): break
			reshapes += 1
	push_error("TT generator: no unique board for n=%d seed=%d" % [n, seed_value])
	return {}

static func _placement(n: int, rng) -> PackedInt32Array:
	var cols := PackedInt32Array(); cols.resize(n)
	var ok := _place_rec(n, 0, 0, cols, rng)
	assert(ok)
	return cols

static func _place_rec(n: int, r: int, used: int, cols: PackedInt32Array, rng) -> bool:
	if r == n: return true
	var order := range(n)
	rng.shuffle(order)
	for c in order:
		if used & (1 << c): continue
		if r > 0 and absi(cols[r - 1] - c) <= 1: continue
		cols[r] = c
		if _place_rec(n, r + 1, used | (1 << c), cols, rng): return true
	return false

static func _grow(n: int, sol: PackedInt32Array, rng) -> PackedInt32Array:
	var reg := PackedInt32Array(); reg.resize(n * n); reg.fill(-1)
	for r in n: reg[r * n + sol[r]] = r      # patch id = row of its planted cake
	var left := n * n - n
	while left > 0:
		var cands := []   # [cell, patch]
		for i in n * n:
			if reg[i] != -1: continue
			var r := i / n; var c := i % n
			if r > 0 and reg[i - n] != -1: cands.append([i, reg[i - n]])
			if r < n - 1 and reg[i + n] != -1: cands.append([i, reg[i + n]])
			if c > 0 and reg[i - 1] != -1: cands.append([i, reg[i - 1]])
			if c < n - 1 and reg[i + 1] != -1: cands.append([i, reg[i + 1]])
		var pick: Array = cands[rng.below(cands.size())]
		reg[pick[0]] = pick[1]
		left -= 1
	return reg

## Kill solution `alt` by moving one of its non-planted cake cells into a neighbouring patch. false = stuck.
static func _reshape(n: int, reg: PackedInt32Array, alt: PackedInt32Array, planted: Dictionary, rng) -> bool:
	var cells := []
	for r in n:
		var i := r * n + alt[r]
		if not planted.has(i): cells.append(i)
	rng.shuffle(cells)
	for i in cells:
		var r: int = i / n; var c: int = i % n
		var opts := []
		if r > 0: opts.append(reg[i - n])
		if r < n - 1: opts.append(reg[i + n])
		if c > 0: opts.append(reg[i - 1])
		if c < n - 1: opts.append(reg[i + 1])
		var g := reg[i]
		var targets := []
		for o in opts:
			if o != g and not targets.has(o): targets.append(o)
		if targets.is_empty(): continue
		if not Rules.patch_connected(n, reg, g, i): continue
		reg[i] = targets[rng.below(targets.size())]
		return true
	return false
