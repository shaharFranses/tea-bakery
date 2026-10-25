## Headless seeded board export CLI + test-vector builder (pattern: sudoku-dash dev a795a1a tools/export_puzzles.gd).
## Usage:
##   godot --headless --path . -s tools/export_boards.gd -- size=7 seeds=0-99 [band=2] [out=/tmp/x.jsonl]   (JSONL, one board per line)
##   godot --headless --path . -s tools/export_boards.gd -- vectors          (rebuilds res://data/test_vectors.json)
## JSONL lines match qa/tt_check.py input: {"n","seed","regions","solution",...}. Rebuilding vectors is a deliberate act:
## any diff means shared seeds / daily boards changed.
extends SceneTree

const Gen = preload("res://game/generator.gd")
const Solver = preload("res://game/solver.gd")
const TtRng = preload("res://game/tt_rng.gd")
const GRADER_PATH = "res://game/grader.gd"

func _entry(n: int, seed_value: int, band: int) -> Dictionary:
	var p: Dictionary = Gen.generate_band(n, band, seed_value) if band > 0 else Gen.generate(n, seed_value)
	var e := {"n": n, "seed": seed_value, "regions": Array(p.regions), "solution": Array(p.solution),
		"solution_count": Solver.new().count(n, p.regions, 2)}
	if band > 0: e["requested_band"] = band
	if ResourceLoader.exists(GRADER_PATH):
		var g = load(GRADER_PATH).grade(n, p.regions)
		e["grade"] = g.grade; e["techniques"] = g.techniques; e["steps"] = g.steps.size()
		e["first_step"] = load(GRADER_PATH).first_step_summary(n, p.regions)
	return e

func _init() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv = s.split("=")
		a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if a.has("vectors"):
		var rng := {}
		for sd in [0, 1, 42, 2026102501]:
			var r = TtRng.new(sd); var outs := []
			for i in 8: outs.append(r.next_u32())
			rng[str(sd)] = outs
		var boards := []
		for n in range(Gen.MIN_N, Gen.MAX_N + 1):
			for sd in [1000, 1001, 1002]:
				boards.append(_entry(n, sd, 0))
		var doc := {"format": 1, "gen": Gen.GEN_VERSION,
			"description": "tea-bakery golden vectors. rng: first 8 TtRng.next_u32() outputs per seed. boards: Gen.generate(n, seed); regions row-major patch ids, solution[r] = cake column in row r. Rebuild only on purpose: tools/export_boards.gd -- vectors",
			"rng": rng, "boards": boards}
		var f := FileAccess.open("res://data/test_vectors.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(doc, " ", true)); f.close()
		print("wrote res://data/test_vectors.json: %d rng seeds, %d boards" % [rng.size(), boards.size()])
		quit(); return
	var n := int(a.get("size", "6")); var band := int(a.get("band", "0"))
	var rs = str(a.get("seeds", "0-9")).split("-"); var lo := int(rs[0]); var hi := int(rs[rs.size() - 1])
	var lines := []
	for sd in range(lo, hi + 1): lines.append(JSON.stringify(_entry(n, sd, band)))
	var text := "\n".join(lines) + "\n"
	if a.has("out"):
		var f := FileAccess.open(a["out"], FileAccess.WRITE); f.store_string(text); f.close()
	else:
		printraw(text)
	quit()
