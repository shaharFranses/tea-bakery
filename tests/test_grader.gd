## Technique ladder (game/grader.gd) on the SPEC v0.2 §4 worked example + tutorial + generated boards.
extends GutTest
const Grader = preload("res://game/grader.gd")
const Gen = preload("res://game/generator.gd")
const Solver = preload("res://game/solver.gd")

func _spec_regions() -> PackedInt32Array:
	var reg := PackedInt32Array()
	for row in ["aaaab", "aaaab", "ccaab", "eeadd", "edddd"]:
		for ch in row: reg.append(ch.unicode_at(0) - 97)
	return reg

func test_spec_example_grade2_and_steps():
	var g = Grader.grade(5, _spec_regions())
	assert_true(g.solved)
	assert_eq(g.grade, 2, "SPEC §4: hardest step T4 -> grade 2")
	assert_eq(Array(g.solution), [2, 4, 1, 3, 0])
	assert_false("T5" in g.techniques or "T6" in g.techniques)
	assert_true("T4" in g.techniques and "T3" in g.techniques)
	var s0 = g.steps[0]
	assert_eq(s0.technique, "T3", "step 1: lemon confined to column E")
	assert_eq(s0.eliminations, [19, 24], "X E4, E5")
	assert_eq(g.steps[1].technique, "T3", "step 2: mint confined to row 3")
	assert_eq(g.steps[1].eliminations, [12, 13, 14], "X C3, D3, E3")
	print("SPEC_EXAMPLE grade=%d steps=%s" % [g.grade, str(g.steps.map(func(s): return s.technique))])

func test_tutorial_grade_le_2():
	var t = Gen.tutorial()
	var g = Grader.grade(t.n, t.regions)
	assert_true(g.solved); assert_lte(g.grade, 2)

func test_ladder_solution_matches_solver_and_t7_flag():
	var solved := 0; var t7 := 0
	for n in [5, 6, 7, 8]:
		for s in 15:
			var p = Gen.generate(n, s)
			var g = Grader.grade(n, p.regions)
			if g.solved:
				solved += 1
				assert_eq(g.solution, p.solution, "ladder solution == unique solution n=%d s=%d" % [n, s])
			else:
				t7 += 1
				assert_eq(g.grade, 5)
	print("LADDER generated boards: solved=%d needs_T7=%d" % [solved, t7])
	assert_gt(solved, 0)

func test_contradiction_on_impossible_board():
	var reg := PackedInt32Array([0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
	var g = Grader.grade(5, reg)
	assert_false(g.solved)

func test_next_hint_fix_and_deduction():
	var reg := _spec_regions(); var sol := PackedInt32Array([2, 4, 1, 3, 0])
	var h = Grader.next_hint(5, reg, sol, [Vector2i(0, 0)], [])
	assert_eq(h.technique, "fix", "wrong cake -> fix first")
	h = Grader.next_hint(5, reg, sol, [], [Vector2i(0, 2)])
	assert_eq(h.technique, "fix", "X on a solution cell -> fix")
	h = Grader.next_hint(5, reg, sol, [], [])
	assert_eq(h.technique, "T3")
	# HN-20: 8 consecutive hint+apply from empty reproduce the ladder and solve the board
	var cakes := []; var marks := []
	for k in 30:
		h = Grader.next_hint(5, reg, sol, cakes, marks)
		if h.is_empty(): break
		if h.place:
			var i: int = h.cells[0]; cakes.append(Vector2i(i / 5, i % 5))
		for j in h.eliminations: marks.append(Vector2i(j / 5, j % 5))
	assert_eq(cakes.size(), 5, "hints alone solve the SPEC example")
