## Where a board comes from (pattern: sudoku-dash dev a795a1a game/puzzle_source.gd).
## 1) a pre-built pack res://game/levels/pack_<n>_g<band>.json (offline, validated: tools/build_packs.gd) if present;
## 2) else runtime generate_band() for small boards (n <= RUNTIME_MAX_N) within RUNTIME_BUDGET_MS;
## 3) else (big board, or budget blown) the unbudgeted generator, flagged in `log` (QA hook).
## Never returns {} for a valid size.
extends RefCounted

const Cfg = preload("res://game/tt_config.gd")
const Gen = preload("res://game/generator.gd")

static var log: Array = []     # [{n, band, seed, source, ms}] for QA dumps / tests

static func pack_path(n: int, band: int) -> String:
	return "res://game/levels/pack_%d_g%d.json" % [n, band]

static func _from_pack(n: int, band: int, seed_value: int) -> Dictionary:
	var path := pack_path(n, band)
	if not FileAccess.file_exists(path): return {}
	var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (doc is Dictionary) or doc.get("boards", []).is_empty(): return {}
	var e: Dictionary = doc.boards[posmod(seed_value, doc.boards.size())]
	var reg := PackedInt32Array()
	for row in e.regions:
		for ch in row: reg.append(ch.unicode_at(0) - 97)
	var sol := PackedInt32Array(); for v in e.solution: sol.append(int(v))
	return {"n": n, "seed": int(e.seed), "regions": reg, "solution": sol, "grade": int(e.grade), "id": e.id,
		"ms": 0.0, "reshapes": 0, "regrows": 0, "nodes": 0}

static func board(n: int, band: int, seed_value: int) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var src := "pack"
	var p := _from_pack(n, band, seed_value)
	if p.is_empty() and n <= Cfg.RUNTIME_MAX_N:
		src = "runtime"
		p = Gen.generate_band(n, band, seed_value, Cfg.BAND_MAX_ATTEMPTS, Cfg.RUNTIME_BUDGET_MS)
		if p.get("timed_out", false) or p.is_empty(): src = "runtime_budget_exceeded"
	if p.is_empty():
		src = "generator_fallback"
		p = Gen.generate_band(n, band, seed_value)
	if p.is_empty(): p = Gen.generate(n, seed_value)
	log.append({"n": n, "band": band, "seed": seed_value, "source": src, "ms": (Time.get_ticks_usec() - t0) / 1000.0})
	p["source"] = src
	return p
