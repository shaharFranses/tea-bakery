## Builds res://game/levels/daily_pool.json: the 400-board Bake of the Day pool (SPEC v1.0.2 §3.4/§3.5 daily, D-11,
## §16.1/§16.4). Index j = day offset from the epoch 2026-11-02 (a Monday); size = sizes_mon_to_sun[weekday(epoch + j)];
## grade <= 2 on weekdays, <= 3 on weekends (weekday bands alternate 2,2,1; weekend 3,2). Boards come from the offline
## generator (generate_band, seed 700000 + j*7 + retry), must be unique (count == 1), ladder-solvable (no T7), in band,
## and distinct (canonical form) from every pack board, every chapter board and every earlier pool board.
## godot --headless --path . -s tools/build_daily.gd   (tests/test_daily_pool.gd re-verifies every entry)
extends SceneTree

const Gen = preload("res://game/generator.gd")
const Solver = preload("res://game/solver.gd")
const Packs = preload("res://tools/build_packs.gd")
const POOL := 400
const SIZES := [6, 6, 7, 7, 7, 8, 8]

func _init() -> void:
	var seen := {}
	for f in DirAccess.get_files_at("res://game/levels"):
		if not f.ends_with(".json") or f == "daily_pool.json": continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://game/levels/" + f))
		for e in d.boards:
			var n := int(e.get("n", e.get("size", 0))); var reg := PackedInt32Array()
			for row in e.regions:
				for ch in row: reg.append(ch.to_lower().unicode_at(0) - 97)
			seen[Packs.canon(n, reg)] = true
	var out := []; var t0 := Time.get_ticks_msec()
	for j in POOL:
		var wd := j % 7; var n: int = SIZES[wd]; var weekend := wd >= 5
		var band: int = ([3, 2][j / 7 % 2] if weekend else [2, 2, 1][j % 3])
		var tries := 0
		while true:
			var sd := 700000 + j * 7 + tries * 3001; tries += 1
			var p := Gen.generate_band(n, band, sd)
			if p.is_empty() or not p.get("band_hit", false): continue
			if Solver.new().count(n, p.regions, 2) != 1: continue
			var k := Packs.canon(n, p.regions)
			if seen.has(k): continue
			seen[k] = true
			var rows := []
			for r in n:
				var s := ""
				for c in n: s += char(65 + p.regions[r * n + c])
				rows.append(s)
			out.append({"id": "d-%03d" % j, "index": j, "size": n, "regions": rows, "solution": Array(p.solution), "grade": int(p.grade),
				"techniques": p.techniques, "steps": int(p.steps), "seed": sd, "band": band, "gen": Gen.GEN_VERSION})
			break
	var doc := {"format": "tt-daily-1", "spec": "SPEC v1.0.2 §3.5 daily", "epoch": "2026-11-02", "pool": POOL, "boards": out}
	var f := FileAccess.open("res://game/levels/daily_pool.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, "", false)); f.close()
	print("daily pool: %d boards in %d ms" % [out.size(), Time.get_ticks_msec() - t0])
	quit(0)
