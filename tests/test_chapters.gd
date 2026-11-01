## Thin-slice chapter content (SPEC v1.0.1 §3.2/§3.5, §6, §16.1, §16.4; TT-AC-02/03/04/24/27 partial): chapters 1-2.
extends GutTest
const Solver = preload("res://game/solver.gd")
const Rules = preload("res://game/rules.gd")
const Grader = preload("res://game/grader.gd")
const Packs = preload("res://tools/build_packs.gd")
const Chapters = preload("res://game/chapters.gd")

var spec := {}

func before_all() -> void:
	var s := FileAccess.get_file_as_string("res://data/spec_tunables.json") if FileAccess.file_exists("res://data/spec_tunables.json") else ""
	spec = JSON.parse_string(s) if s != "" else {}

const SPEC_CH := {1: {"sizes": [5, 5, 5, 5, 5], "grades": [1, 1, 1, 1, 2], "tutorial": [1, 2, 3]},
	2: {"sizes": [5, 6, 5, 6, 6], "grades": [2, 2, 1, 2, 2]}}

func test_thin_slice_chapters_present() -> void:
	assert_true(Chapters.available(1) and Chapters.available(2))
	assert_true(Chapters.count_available() >= 2)

func test_every_board_unique_graded_valid() -> void:
	var shapes := {}
	for ch in SPEC_CH:
		for b in range(1, 6):
			var p := Chapters.board(ch, b)
			assert_eq(p.id, "c%d-b%d" % [ch, b])
			assert_eq(p.n, SPEC_CH[ch].sizes[b - 1], "%s size" % p.id)
			assert_eq(Solver.new().count(p.n, p.regions, 2), 1, "%s unique solution" % p.id)
			assert_true(Rules.regions_valid(p.n, p.regions), "%s regions valid" % p.id)
			assert_true(Rules.is_solution(p.n, p.regions, Rules.cols_to_cells(p.solution)), "%s solution valid" % p.id)
			var g = Grader.grade(p.n, p.regions)
			assert_true(g.solved, "%s solved by the ladder (no T7)" % p.id)
			assert_eq(g.grade, p.grade, "%s stored grade == ladder" % p.id)
			assert_eq(p.grade, SPEC_CH[ch].grades[b - 1], "%s spec grade" % p.id)
			for gv in p.givens: assert_eq(p.solution[gv.x], gv.y, "%s given on the solution" % p.id)
			var k := Packs.canon(p.n, p.regions)
			assert_false(shapes.has(k), "%s distinct" % p.id); shapes[k] = true

func _free_after_givens(p: Dictionary) -> Array:
	var n: int = p.n; var free := []
	for i in n * n:
		var ok := true
		for g in p.givens:
			var gi: int = g.x * n + g.y
			if i == gi or i / n == g.x or i % n == g.y or p.regions[i] == p.regions[gi] or (absi(i / n - g.x) <= 1 and absi(i % n - g.y) <= 1): ok = false
		if ok: free.append(i)
	return free

func test_tutorial_trays() -> void:
	for b in [1, 2, 3]:
		var p := Chapters.board(1, b)
		assert_true(p.tutorial, "c1-b%d is a tutorial tray" % b)
		assert_ne(p.coach, "", "exactly one coach line")
		assert_false("\n" in p.coach)
		assert_true(p.n - p.givens.size() <= 2, "c1-b%d solvable with <=2 placements" % b)
		assert_eq(p.targets.size(), 1)
		assert_eq(p.solution[p.targets[0].x], p.targets[0].y, "target is a solution cell")
	assert_eq(Chapters.board(1, 1).givens.size(), 4, "b1: 4 givens, 1 placement")
	assert_eq(_free_after_givens(Chapters.board(1, 1)).size(), 1)
	for b in [4, 5]: assert_false(Chapters.board(1, b).tutorial, "c1-b%d normal tray (no coach)" % b)

func test_recipes_and_decor_names() -> void:
	assert_eq(Chapters.RECIPES.size(), 8); assert_eq(Chapters.DECOR.size(), 8)
	for f in Chapters.DECOR_FILES: assert_true(ResourceLoader.exists("res://assets/decor/%s@2x.png" % f), f)
	for i in 8: assert_true(ResourceLoader.exists("res://assets/recipes/recipe_%d@2x.png" % (i + 1)))
