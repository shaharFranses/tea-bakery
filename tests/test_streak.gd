## U1 streak: the 11 SPEC v0.3 §7.1 vectors (data/streak_vectors.json, copied verbatim from the spec) + Daily state
## with a mocked clock (game/clock.gd): V8 forced double completion counts once, V9 after-midnight finish counts for
## the board date, V10 clock moved back never shortens, fresh-streak line.
extends GutTest
const Streak = preload("res://game/streak.gd")
const Daily = preload("res://game/daily.gd")
const Clock = preload("res://game/clock.gd")

func after_each(): Clock.reset()

func _vectors() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/streak_vectors.json")).vectors

func test_eleven_vectors_streak():
	var v := _vectors()
	assert_eq(v.size(), 11)
	for x in v:
		assert_eq(Streak.streak(x.S, x.today), int(x.streak), "%s streak" % x.id)
		if x.has("best"):
			var bt = Streak.best_total(x.S)
			assert_eq([bt.best, bt.total], [int(x.best), int(x.total)], "%s best/total" % x.id)

func test_vectors_through_daily_with_mock_clock():
	for x in _vectors():
		var d = Daily.new(); var last := {}
		for date in x.S:
			Clock.set_local_now(date + "T10:00")
			if d.open(Clock.local_date()): last = d.complete(Clock.local_date())
			else: last = d.complete(Clock.local_date(), date)     # V8: forced second completion (hook) counts once
		Clock.set_local_now(x.today + "T10:00")
		var s = d.summary(Clock.local_date())
		assert_eq(s.streak, int(x.streak), "%s via Daily" % x.id)
		if x.has("best"): assert_eq([s.best_streak, s.total_bakes], [int(x.best), int(x.total)], x.id)
		if x.get("fresh_line", false): assert_true(last.fresh_line, "%s fresh line" % x.id)
		elif not x.S.is_empty(): assert_false(last.fresh_line, "%s no fresh line" % x.id)

func test_v9_after_midnight_counts_for_board_date():
	var d = Daily.new()
	Clock.set_local_now("2026-11-02T09:00"); d.open(Clock.local_date()); d.complete(Clock.local_date())
	Clock.set_local_now("2026-11-03T23:58"); assert_true(d.open(Clock.local_date()))
	Clock.set_local_now("2026-11-04T00:03")
	var r = d.complete(Clock.local_date())
	assert_eq(r.date, "2026-11-03"); assert_eq(r.streak, 2)
	assert_false(d.is_done("2026-11-04"), "11-04 daily still open")

func test_v8_forced_double_completion_counts_once():
	var d = Daily.new()
	for date in ["2026-11-02", "2026-11-03"]:
		Clock.set_local_now(date + "T10:00"); d.open(date); d.complete(date)
	var r = d.complete("2026-11-03", "2026-11-03")
	assert_false(r.counted); assert_eq(r.total_bakes, 2); assert_eq(r.streak, 2)
	assert_false(d.open("2026-11-03"), "daily not replayable")

func test_clock_hook_runtime_and_session():
	assert_true(Clock.set_local_now("2026-11-03T23:58"))
	assert_eq(Clock.local_date(), "2026-11-03")
	assert_true(Clock.set_local_now("2026-11-04T00:03"))
	assert_eq(Clock.local_date(), "2026-11-04")
	assert_eq(Clock.session_s(), 0.0, "no session before gameplayStart")
	Clock.start_session(); Clock.set_session_s(299)
	assert_almost_eq(Clock.session_s(), 299.0, 0.05)
