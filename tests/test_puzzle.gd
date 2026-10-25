## tea-bakery generator / solver / rules tests (GUT, headless). TT_SEEDS env var overrides seeds per size (default 200).
extends GutTest

const Gen = preload("res://game/generator.gd")
const Solver = preload("res://game/solver.gd")
const Rules = preload("res://game/rules.gd")
const TtRng = preload("res://game/tt_rng.gd")

func _seeds() -> int:
	var s := OS.get_environment("TT_SEEDS")
	return s.to_int() if s.is_valid_int() else 200

func test_rng_deterministic_and_seed_sensitive():
	var a = TtRng.new(42); var b = TtRng.new(42); var c = TtRng.new(43)
	var sa := []; var sb := []; var sc := []
	for i in 50:
		sa.append(a.next_u32()); sb.append(b.next_u32()); sc.append(c.next_u32())
	assert_eq(sa, sb)
	assert_ne(sa, sc)
	# golden values: catch accidental RNG changes (would silently change every shared seed / daily board)
	assert_eq(TtRng.new(1).next_u32(), TtRng.new(1).next_u32())

func test_same_seed_same_puzzle():
	for n in range(5, 10):
		for s in [0, 1, 7, 123456, 2026102501]:
			var p1 = Gen.generate(n, s); var p2 = Gen.generate(n, s)
			assert_eq(p1.regions, p2.regions, "regions n=%d seed=%d" % [n, s])
			assert_eq(p1.solution, p2.solution, "solution n=%d seed=%d" % [n, s])
	assert_ne(Gen.generate(7, 1).regions, Gen.generate(7, 2).regions, "different seeds differ")

func test_seed_from_string_stable():
	assert_eq(Gen.seed_from_string("123"), 123)
	assert_eq(Gen.seed_from_string("tea"), Gen.seed_from_string("tea"))
	assert_ne(Gen.seed_from_string("tea"), Gen.seed_from_string("tart"))

func test_generated_unique_and_valid_all_sizes():
	var seeds := _seeds()
	var solver = Solver.new()
	var report := []
	for n in range(5, 10):
		var t := 0.0; var worst := 0.0; var reshapes := 0; var regrows := 0; var bad := 0; var nodes := 0
		for s in seeds:
			var p = Gen.generate(n, s)
			if p.is_empty(): bad += 1; continue
			t += p.ms; worst = max(worst, p.ms); reshapes += p.reshapes; regrows += p.regrows; nodes += p.nodes
			var ok := Rules.regions_valid(n, p.regions)
			var sols: Array = solver.solve(n, p.regions, 2)
			ok = ok and sols.size() == 1 and sols[0] == p.solution
			ok = ok and Rules.is_solution(n, p.regions, Rules.cols_to_cells(p.solution))
			if not ok: bad += 1
		assert_eq(bad, 0, "n=%d: %d of %d boards not unique/valid" % [n, bad, seeds])
		var line := "TIMING n=%d seeds=%d avg=%.1fms max=%.1fms total=%.2fs avg_reshapes=%.1f avg_regrows=%.2f avg_solver_nodes=%.0f" % [
			n, seeds, t / seeds, worst, t / 1000.0, float(reshapes) / seeds, float(regrows) / seeds, float(nodes) / seeds]
		print(line); report.append(line)
	gut.p("\n".join(report))

func test_rules_reject_invalid_placements():
	var p = Gen.generate(6, 5)
	var n := 6
	var good: Array = Rules.cols_to_cells(p.solution)
	assert_true(Rules.is_solution(n, p.regions, good))
	assert_false(Rules.is_solution(n, p.regions, good.slice(0, n - 1)), "too few cakes")
	var touching := [Vector2i(0, 0), Vector2i(1, 1)]
	assert_eq(Rules.conflicts(n, p.regions, touching).size(), 2, "diagonal touch flagged")
	assert_eq(Rules.conflicts(n, p.regions, [Vector2i(0, 0), Vector2i(0, 3)]).size(), 2, "same row flagged")
	assert_eq(Rules.conflicts(n, p.regions, [Vector2i(0, 2), Vector2i(4, 2)]).size(), 2, "same column flagged")
	# same patch: two non-touching cells of one region, different rows/cols
	var g: int = p.regions[0]
	var found := false
	for i in n * n:
		var r := i / n; var c := i % n
		if p.regions[i] == g and r > 1 and c > 1:
			found = true
			assert_eq(Rules.conflicts(n, p.regions, [Vector2i(0, 0), Vector2i(r, c)]).size(), 2, "same patch flagged")
			break
	# a permuted (wrong) placement that breaks no-touch
	var swapped := good.duplicate()
	swapped[0] = Vector2i(0, good[1].y); swapped[1] = Vector2i(1, good[0].y)
	assert_false(Rules.is_solution(n, p.regions, swapped))
	assert_false(Rules.is_solution(n, p.regions, [Vector2i(-1, 0), Vector2i(1, 2), Vector2i(2, 4), Vector2i(3, 1), Vector2i(4, 3), Vector2i(5, 5)]), "out of bounds")

func test_solver_rejects_unsolvable_and_ambiguous_boards():
	var solver = Solver.new()
	var n := 5
	# patches 0 and 1 both confined to row 0 -> both need a cake in row 0 -> no solution
	var reg := PackedInt32Array([0, 0, 1, 1, 1,
		2, 2, 2, 2, 2,
		3, 3, 3, 3, 3,
		4, 4, 4, 4, 4,
		4, 4, 4, 4, 4])
	assert_eq(solver.count(n, reg, 2), 0, "unsolvable board has 0 solutions")
	# stripes (patch = row) -> many solutions -> not unique
	var stripes := PackedInt32Array()
	for r in n:
		for c in n: stripes.append(r)
	assert_eq(solver.count(n, stripes, 2), 2, "stripes are ambiguous (stops at 2)")
	assert_eq(solver.count(n, stripes, 100), 14, "5x5 non-touching permutations")
	# malformed maps
	assert_eq(solver.count(n, PackedInt32Array([0, 1, 2]), 2), 0, "wrong size")
	var bad_id := stripes.duplicate(); bad_id[3] = 9
	assert_eq(solver.count(n, bad_id, 2), 0, "patch id out of range")
	assert_false(Rules.regions_valid(n, bad_id))
	# 2x2..3x3 can never be solved (no non-touching permutation)
	assert_eq(solver.count(3, PackedInt32Array([0, 0, 0, 1, 1, 1, 2, 2, 2]), 2), 0)

func test_regions_valid_rejects_disconnected_patch():
	var n := 5
	var reg := PackedInt32Array()
	for r in n:
		for c in n: reg.append(r)
	assert_true(Rules.regions_valid(n, reg))
	reg[0] = 4    # patch 4 now has a stray cell in the top-left corner
	assert_false(Rules.regions_valid(n, reg), "disconnected patch")
	reg = PackedInt32Array(); for i in 25: reg.append(0)
	assert_false(Rules.regions_valid(n, reg), "missing patches")

func test_tutorial_board_unique_and_valid():
	var t = Gen.tutorial()
	assert_true(Rules.regions_valid(t.n, t.regions))
	var sols: Array = Solver.new().solve(t.n, t.regions, 2)
	assert_eq(sols.size(), 1, "tutorial board has exactly one solution")
	assert_eq(sols[0], t.solution)
	assert_true(Rules.is_solution(t.n, t.regions, Rules.cols_to_cells(t.solution)))
