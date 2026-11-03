## Chapter content (SPEC v1.1 §3.2/§3.5, §6, §16.1, §16.4; TT-AC-02/03/04/24/27/54): chapters 1-8 x 12 levels, 96 boards.
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

const SPEC_CH := {
	1: {"sizes": [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5], "grades": [1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 2], "tutorial": [1, 2, 3]},
	2: {"sizes": [5, 6, 5, 6, 6, 5, 6, 6, 5, 6, 6, 6], "grades": [2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 1, 2]},
	3: {"sizes": [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6], "grades": [2, 2, 1, 2, 3, 2, 2, 1, 3, 2, 1, 3]},
	4: {"sizes": [6, 7, 6, 7, 7, 7, 6, 7, 7, 6, 7, 7], "grades": [2, 2, 1, 2, 3, 2, 2, 1, 3, 2, 1, 3]},
	5: {"sizes": [7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7], "grades": [2, 3, 1, 2, 3, 2, 2, 1, 3, 2, 1, 3]},
	6: {"sizes": [7, 8, 7, 8, 8, 8, 7, 8, 8, 7, 8, 8], "grades": [2, 2, 1, 3, 2, 2, 3, 1, 2, 3, 1, 3]},
	7: {"sizes": [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8], "grades": [2, 3, 1, 3, 2, 2, 3, 1, 2, 3, 1, 3]},
	8: {"sizes": [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8], "grades": [3, 2, 3, 4, 2, 3, 2, 3, 2, 3, 1, 3]}}   # SPEC v1.1 §3.5

## The §3.5 tunables JSON block of the repo's spec/SPEC.md (source of truth for sizes, grades, names).
func _tunables() -> Dictionary:
	var t := FileAccess.get_file_as_string("res://spec/SPEC.md")
	var a := t.find("```json tunables"); var b := t.find("```", a + 10)
	return JSON.parse_string(t.substr(a + 16, b - a - 16))

func test_chapters_match_spec_tunables() -> void:
	var tun := _tunables()
	assert_eq(tun.chapters.size(), 8)
	for c in tun.chapters:
		var ch := int(c.id)
		assert_eq(SPEC_CH[ch].sizes, c.sizes.map(func(v): return int(v)), "ch%d sizes == spec" % ch)
		assert_eq(SPEC_CH[ch].grades, c.grades.map(func(v): return int(v)), "ch%d grades == spec" % ch)
		assert_eq(Chapters.RECIPES[ch - 1], c.recipe, "ch%d recipe name == spec" % ch)
		assert_eq(Chapters.DECOR[ch - 1], c.decor, "ch%d decor name == spec" % ch)
	assert_eq(Chapters.RECIPES[4], "Cherry Bakewell", "v1.0.2 card 5")
	assert_eq(Chapters.count_available(), 8)

func test_no_shipped_board_over_8() -> void:
	for ch in SPEC_CH:
		for b in range(1, Chapters.BOARDS + 1): assert_lte(Chapters.board(ch, b).n, 8)

func test_thin_slice_chapters_present() -> void:
	assert_true(Chapters.available(1) and Chapters.available(2))
	assert_eq(Chapters.count_available(), 8)

func test_every_board_unique_graded_valid() -> void:
	var shapes := {}
	for ch in SPEC_CH:
		for b in range(1, Chapters.BOARDS + 1):
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
	for b in range(4, Chapters.BOARDS + 1): assert_false(Chapters.board(1, b).tutorial, "c1-b%d normal tray (no coach)" % b)

## SPEC v1.1: boards 1-5 of every chapter are the v1.0.2 boards (pinned by their pack source ids), 12 levels per chapter.
const V102_SOURCES := {1: ["5-g1-0000", "5-g1-0001", "5-g1-0002", "5-g1-0003", "5-g2-0000"],
	2: ["5-g2-0001", "6-g2-0000", "5-g1-0004", "6-g2-0001", "6-g2-0002"], 8: ["8-g3-0003", "8-g2-0004", "8-g3-0004", "8-g4-0000", "8-g2-0005"]}
func test_v102_boards_kept_and_12_levels() -> void:
	assert_eq(Chapters.BOARDS, 12)
	for ch in SPEC_CH: assert_eq(Chapters.doc(ch).boards.size(), 12, "ch%d has 12 levels" % ch)
	for ch in V102_SOURCES:
		for b in 5: assert_eq(Chapters.board(ch, b + 1).source_id, V102_SOURCES[ch][b], "c%d-b%d unchanged" % [ch, b + 1])

func test_level_numbers() -> void:
	assert_eq(Chapters.level(1, 1), 1); assert_eq(Chapters.level(2, 1), 13); assert_eq(Chapters.level(8, 12), 96)
	assert_eq(Chapters.id_of_level(14), "c2-b2"); assert_eq(Chapters.id_of_level(96), "c8-b12")
	assert_eq(Chapters.level_of("c3-b12"), 36); assert_eq(Chapters.level_of("d-2026-11-03"), 0)
	for lv in range(1, 97): assert_eq(Chapters.level_of(Chapters.id_of_level(lv)), lv)

func test_recipes_and_decor_names() -> void:
	assert_eq(Chapters.RECIPES.size(), 8); assert_eq(Chapters.DECOR.size(), 8)
	for f in Chapters.DECOR_FILES: assert_true(ResourceLoader.exists("res://assets/decor/%s@2x.png" % f), f)
	for i in 8: assert_true(ResourceLoader.exists("res://assets/recipes/recipe_%d@2x.png" % (i + 1)))
