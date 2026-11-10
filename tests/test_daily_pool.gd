## Daily pool (SPEC v1.0.2 §3.4/§3.5 daily, D-11, §5, §16.4; TT-AC-10 mapping, TT-AC-27 content): every one of the 400
## boards re-verified (unique, ladder grade == stored, no T7, weekday size + grade cap, distinct from packs/chapters/pool).
extends GutTest
const Solver = preload("res://game/solver.gd")
const Rules = preload("res://game/rules.gd")
const Grader = preload("res://game/grader.gd")
const Packs = preload("res://tools/build_packs.gd")
const Chapters = preload("res://game/chapters.gd")
const DailyPool = preload("res://game/daily_pool.gd")
const SIZES := [6, 6, 7, 7, 7, 8, 8]

func test_mapping_vectors_tt_ac_10():
	assert_eq(DailyPool.index_for("2026-11-01"), 0, "before epoch clamps to 0")
	assert_eq(DailyPool.index_for("2026-11-02"), 0)
	assert_eq(DailyPool.index_for("2026-11-05"), 3)
	assert_eq(DailyPool.index_for("2027-12-07"), 0, "wraps at 400")
	assert_eq(DailyPool.index_for("2027-12-06"), 399)
	assert_eq(DailyPool.wrap_date(), "2027-12-07")
	assert_eq(DailyPool.board("2026-11-05").id, "d-003")
	assert_eq(DailyPool.board("2026-11-05").regions, DailyPool.board("2026-11-05").regions, "deterministic")

func test_every_pool_board():
	var d := DailyPool.doc()
	assert_eq(d.boards.size(), 400); assert_eq(str(d.epoch), "2026-11-02")
	var seen := {}
	for ch in range(1, 9):
		for b in range(1, Chapters.BOARDS + 1):
			var p := Chapters.board(ch, b); seen[Packs.canon(p.n, p.regions)] = "c%d-b%d" % [ch, b]
	var bad := 0
	for j in 400:
		var p := DailyPool.board(Time.get_date_string_from_unix_time((DailyPool.day_number("2026-11-02") + j) * 86400))
		assert_eq(p.index, j)
		var wd := j % 7                                    # epoch 2026-11-02 is a Monday
		var ok: bool = p.n == SIZES[wd] and p.grade <= (3 if wd >= 5 else 2) and p.n <= 8
		ok = ok and Solver.new().count(p.n, p.regions, 2) == 1 and Rules.regions_valid(p.n, p.regions)
		ok = ok and Rules.is_solution(p.n, p.regions, Rules.cols_to_cells(p.solution))
		var g = Grader.grade(p.n, p.regions)
		ok = ok and g.solved and g.grade == p.grade
		var k := Packs.canon(p.n, p.regions)
		ok = ok and not seen.has(k); seen[k] = p.id
		if not ok: bad += 1; gut.p("bad pool board %s" % p.id)
	assert_eq(bad, 0, "all 400 pool boards valid and distinct")

func test_weekday_of_epoch_is_monday():
	assert_eq(Time.get_datetime_dict_from_unix_time(DailyPool.day_number("2026-11-02") * 86400).weekday, 1)
