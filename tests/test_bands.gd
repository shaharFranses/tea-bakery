## Grade bands per size + budgeted runtime source with fallback (never {}). Timings printed, never asserted (SD gotcha 3).
extends GutTest
const Gen = preload("res://game/generator.gd")
const Src = preload("res://game/puzzle_source.gd")
const Grader = preload("res://game/grader.gd")
const Solver = preload("res://game/solver.gd")
const Cfg = preload("res://game/tt_config.gd")

func test_valid_bands_and_mobile_cap():
	assert_eq(Gen.valid_bands(5), [1, 2])
	assert_true(Cfg.MAX_N_MOBILE == 8)
	for n in range(5, 10): assert_false(Gen.valid_bands(n).is_empty())

func test_generate_band_hits_and_is_deterministic():
	var hits := 0; var total := 0
	for n in [5, 6, 7]:
		for band in Gen.valid_bands(n):
			for s in 3:
				var p = Gen.generate_band(n, band, s)
				total += 1
				assert_false(p.is_empty())
				assert_eq(Solver.new().count(n, p.regions, 2), 1)
				assert_eq(Grader.grade(n, p.regions).grade, p.grade, "stored grade == recomputed")
				if p.band_hit: hits += 1
				var q = Gen.generate_band(n, band, s)
				assert_eq(q.regions, p.regions, "deterministic n=%d band=%d seed=%d" % [n, band, s])
	print("BANDS hit %d/%d" % [hits, total])
	assert_gt(hits, total / 2)

func test_puzzle_source_never_empty_and_logs_source():
	Src.log.clear()
	for n in [5, 6, 8]:
		var p = Src.board(n, 2, 11)
		assert_false(p.is_empty(), "n=%d" % n)
		assert_eq(p.n, n)
	assert_eq(Src.log.size(), 3)
	assert_true(Src.log[2].source in ["pack", "generator_fallback"], "8x8 never generated under the runtime budget")
	print("SOURCE log: ", Src.log)
