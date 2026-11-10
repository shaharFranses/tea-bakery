## S1-01 (thin-07f7ba8, AN-53 console_zero): PKD_QA.show("daily:today") resolves "today" to the local date (or the
## set_date override) BEFORE DailyPool.day_number, so no "Invalid ISO 8601 date string" USER ERROR is logged.
extends GutTest
const Clock = preload("res://game/clock.gd")
const QA = preload("res://debug/tt_qa_game.gd")
const Progress = preload("res://game/progress.gd")

func after_each(): Clock.reset()

func test_resolve_date():
	assert_eq(Clock.resolve_date("today"), Clock.local_date())
	assert_eq(Clock.resolve_date(" Today "), Clock.local_date())
	assert_eq(Clock.resolve_date(""), Clock.local_date())
	assert_eq(Clock.resolve_date("2026-11-07"), "2026-11-07")
	assert_eq(Clock.resolve_date("2028-02-29"), "2028-02-29")
	for bad in ["tomorrow", "2026-13-01", "2026-02-29", "2026-04-31", "2026-11-7", "20261107", "2026-11-07T10:00", "abcd-ef-gh"]:
		assert_eq(Clock.resolve_date(bad), "", bad)

func test_today_honours_set_date_override():
	assert_true(Clock.set_local_now("2027-02-14T09:30"))
	assert_eq(Clock.resolve_date("today"), "2027-02-14")

func test_bad_strings_rejected_without_parser():
	for bad in ["todayT12:00", "2026-11-07Tnoon", "2026-02-30T10:00", "2026-11-07T25:00", "2026-11-07T10:61", "x"]:
		assert_false(Clock.set_local_now(bad), bad)

func test_show_daily_today_opens_todays_daily():
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	m._on_intro_finished()
	Clock.set_local_now("2026-11-10T08:00")
	var r := QA.show(m, "daily:today")
	assert_eq(r, "open 2026-11-10", r)
	assert_eq(m.mode, "daily")
	assert_string_contains(QA.show(m, "daily:nope"), "bad date")
