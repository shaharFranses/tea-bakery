## Offline pack builder (pattern: sudoku-dash dev a795a1a tools/build_packs.gd). Shipped boards come from here (SPEC D-21).
## godot --headless --path . -s tools/build_packs.gd -- [sizes=5-9] [count=40] [start=0]
## Writes res://game/levels/pack_<n>_g<band>.json for every band in Cfg.VALID_BANDS[n]. Each entry is regenerable from
## (n, band, seed) with generator GEN_VERSION; only band hits are kept; unique (count==1), solvable without T7, and
## distinct up to the 8 board symmetries + patch relabelling. tests/test_packs.gd and qa/tt_check.py re-verify every entry.
extends SceneTree

const Gen = preload("res://game/generator.gd")
const Grader = preload("res://game/grader.gd")
const Solver = preload("res://game/solver.gd")

static func canon(n: int, regions: PackedInt32Array) -> String:
	var best := ""
	for t in 8:
		var m := {}; var nxt := 0; var s := ""
		for r in n:
			for c in n:
				var rr := r; var cc := c
				if t & 1: cc = n - 1 - cc
				if t & 2: rr = n - 1 - rr
				if t & 4: var tmp := rr; rr = cc; cc = tmp
				var v := regions[rr * n + cc]
				if not m.has(v): m[v] = nxt; nxt += 1
				s += char(97 + m[v])
		if best == "" or s < best: best = s
	return best

func _init() -> void:
	var a := {"sizes": "5-9", "count": "40", "start": "0"}
	for s in OS.get_cmdline_user_args():
		var kv = s.split("="); a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var sz = a.sizes.split("-"); var lo := int(sz[0]); var hi := int(sz[-1])
	var count := int(a.count); var start := int(a.start)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://game/levels"))
	for n in range(lo, hi + 1):
		for band in Gen.valid_bands(n):
			var t0 := Time.get_ticks_msec(); var boards := []; var seen := {}; var sd := start; var miss := 0
			while boards.size() < count and sd < start + count * 20:
				var p := Gen.generate_band(n, band, sd)
				sd += 1
				if p.is_empty() or not p.get("band_hit", false): miss += 1; continue
				var k := canon(n, p.regions)
				if seen.has(k): continue
				assert(Solver.new().count(n, p.regions, 2) == 1)
				seen[k] = true
				var rows := []
				for r in n:
					var row := ""
					for c in n: row += char(97 + p.regions[r * n + c])
					rows.append(row)
				boards.append({"id": "%d-g%d-%04d" % [n, band, boards.size()], "n": n, "seed": p.seed, "band": band,
					"regions": rows, "solution": Array(p.solution), "grade": p.grade, "techniques": p.techniques, "steps": p.steps})
			var doc := {"format": 1, "gen": Gen.GEN_VERSION, "n": n, "band": band, "boards": boards}
			var f := FileAccess.open("res://game/levels/pack_%d_g%d.json" % [n, band], FileAccess.WRITE)
			f.store_string(JSON.stringify(doc, " ")); f.close()
			print("PACK n=%d g%d: %d boards, seeds %d..%d, misses %d, %d ms" % [n, band, boards.size(), start, sd - 1, miss, Time.get_ticks_msec() - t0])
	quit(0)
