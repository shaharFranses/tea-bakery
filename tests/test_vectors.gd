## Golden vectors (data/test_vectors.json, built by tools/export_boards.gd -- vectors). Pinned literal outputs:
## catches any silent change to the RNG / generator / grader, which would re-roll every shared seed and daily board.
extends GutTest
const Gen = preload("res://game/generator.gd")
const TtRng = preload("res://game/tt_rng.gd")
const Rules = preload("res://game/rules.gd")
const Solver = preload("res://game/solver.gd")

var doc: Dictionary
const PINNED_SEED1 := [3745685276, 411726028, 2229840677]   # independently recomputed in Python (xorshift32 13/17/5)

func before_all():
	doc = JSON.parse_string(FileAccess.get_file_as_string("res://data/test_vectors.json"))

func test_rng_matches_pinned_literals():
	# literal values, independent of the file (seed 1 first outputs)
	var r = TtRng.new(1)
	var got := [r.next_u32(), r.next_u32(), r.next_u32()]
	assert_eq(got, PINNED_SEED1, "TtRng(1) first 3 outputs")
	for sd in doc.rng:
		var rr = TtRng.new(int(sd)); var outs := []
		for i in doc.rng[sd].size(): outs.append(rr.next_u32())
		var want := []
		for v in doc.rng[sd]: want.append(int(v))
		assert_eq(outs, want, "rng seed %s" % sd)

func test_boards_match_vectors():
	assert_gt(doc.boards.size(), 0)
	for b in doc.boards:
		var n := int(b.n)
		var p = Gen.generate(n, int(b.seed))
		var want_reg := PackedInt32Array(); for v in b.regions: want_reg.append(int(v))
		var want_sol := PackedInt32Array(); for v in b.solution: want_sol.append(int(v))
		assert_eq(p.regions, want_reg, "regions n=%d seed=%d" % [n, b.seed])
		assert_eq(p.solution, want_sol, "solution n=%d seed=%d" % [n, b.seed])
		assert_eq(int(b.solution_count), 1)
		assert_eq(Solver.new().count(n, want_reg, 2), 1)
		assert_true(Rules.is_solution(n, want_reg, Rules.cols_to_cells(want_sol)))
