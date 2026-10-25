## Every shipped pack entry re-verified in-engine: unique, rules-valid solution, connected patches, stored grade == ladder grade,
## band respected, ids/shapes distinct. (Independent cross-language check: qa/tt_check.py.)
extends GutTest
const Solver = preload("res://game/solver.gd")
const Rules = preload("res://game/rules.gd")
const Grader = preload("res://game/grader.gd")
const Packs = preload("res://tools/build_packs.gd")

func test_all_packs():
	var dir := DirAccess.open("res://game/levels")
	if dir == null:
		pending("no packs built yet"); return
	var files := Array(dir.get_files()).filter(func(f): return f.begins_with("pack_") and f.ends_with(".json"))
	var total := 0; var ids := {}
	for f in files:
		var doc = JSON.parse_string(FileAccess.get_file_as_string("res://game/levels/" + f))
		var shapes := {}
		for e in doc.boards:
			var n := int(e.n); var reg := PackedInt32Array()
			for row in e.regions:
				for ch in row: reg.append(ch.unicode_at(0) - 97)
			var sol := PackedInt32Array(); for v in e.solution: sol.append(int(v))
			assert_eq(Solver.new().count(n, reg, 2), 1, "%s unique" % e.id)
			assert_true(Rules.is_solution(n, reg, Rules.cols_to_cells(sol)) and Rules.regions_valid(n, reg), "%s solution valid" % e.id)
			var g = Grader.grade(n, reg)
			assert_true(g.solved, "%s no T7" % e.id)
			assert_eq(g.grade, int(e.grade), "%s grade" % e.id)
			assert_eq(int(e.grade), int(doc.band), "%s in band" % e.id)
			assert_false(ids.has(e.id)); ids[e.id] = true
			var k := Packs.canon(n, reg)
			assert_false(shapes.has(k), "%s distinct" % e.id); shapes[k] = true
			total += 1
	print("PACKS verified %d boards in %d files" % [total, files.size()])
	assert_gt(total, 0)
