## Fixture: SPEC v0.2 §4 worked example (/workspace/pipeline-ops/games/tea-and-tarts/SPEC.md), re-validated with the
## shipped GDScript rules + solver (TT-AC-01/02/04). Board letters a..e -> patch ids 0..4; solution "C1, E2, B3, D4, A5"
## (column letter + 1-based row) -> col per row [2, 4, 1, 3, 0].
extends GutTest

const Rules = preload("res://game/rules.gd")
const Solver = preload("res://game/solver.gd")

const ROWS := ["aaaab", "aaaab", "ccaab", "eeadd", "edddd"]
const SOLUTION_SPEC := ["C1", "E2", "B3", "D4", "A5"]

func _regions() -> PackedInt32Array:
	var reg := PackedInt32Array()
	for row in ROWS:
		for ch in row: reg.append(ch.unicode_at(0) - 97)
	return reg

func _solution_cells() -> Array:
	var cells := []
	for s in SOLUTION_SPEC:
		cells.append(Vector2i(s.substr(1).to_int() - 1, s.unicode_at(0) - 65))   # (row, col)
	cells.sort_custom(func(a, b): return a.x < b.x)
	return cells

func test_spec_example_region_map_valid():
	assert_true(Rules.regions_valid(5, _regions()), "5 patches, each 4-connected, covering all 25 cells")

func test_spec_example_solution_satisfies_rules():
	var reg := _regions(); var cells := _solution_cells()
	var rows := {}; var cols := {}; var pats := {}
	for p in cells:
		rows[p.x] = true; cols[p.y] = true; pats[reg[p.x * 5 + p.y]] = true
	assert_eq(rows.size(), 5, "one cake per row"); assert_eq(cols.size(), 5, "one cake per column")
	assert_eq(pats.size(), 5, "one cake per patch")
	var touching := []
	for i in cells.size():
		for j in range(i + 1, cells.size()):
			if absi(cells[i].x - cells[j].x) <= 1 and absi(cells[i].y - cells[j].y) <= 1: touching.append([cells[i], cells[j]])
	assert_eq(touching, [], "no two cakes touch (8-neighbourhood)")
	assert_eq(Rules.conflicts(5, reg, cells), [], "rules module reports no conflicts")
	assert_true(Rules.is_solution(5, reg, cells))
	print("SPEC_EXAMPLE solution cells (row,col 0-based): ", cells)

func test_spec_example_unique():
	var s = Solver.new()
	var sols: Array = s.solve(5, _regions(), 100)
	print("SPEC_EXAMPLE solution_count=%d solver_nodes=%d sols=%s" % [sols.size(), s.nodes, str(sols)])
	assert_eq(sols.size(), 1, "exactly one solution")
	assert_eq(sols[0], PackedInt32Array([2, 4, 1, 3, 0]))
