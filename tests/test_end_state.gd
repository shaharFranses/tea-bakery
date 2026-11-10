## §7.2 / TT-AC-51: ch8 end -> "All recipes baked" once -> Home (Bake of the Day primary + Levels);
## replays unlock nothing, fire no chapter events, request no midgame; all done boots to Home.
extends GutTest
const Progress = preload("res://game/progress.gd")
const Chapters = preload("res://game/chapters.gd")
const Cells = preload("res://game/cells.gd")

func _main_all_but_last() -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for ch in range(1, 9):
		for b in range(1, Chapters.BOARDS + 1):
			if not (ch == 8 and b == Chapters.BOARDS): m.progress.mark_solved("c%d-b%d" % [ch, b])
		if ch < 8: m.progress.unlock_chapter(ch)
	m.ad_policy.chapters_completed = 7
	m._on_intro_finished()
	m.open_board("c8-b12")
	await wait_frames(2)
	return m

func _solve(m) -> void:
	var sol: PackedInt32Array = m.puzzle.solution
	for r in m.n:
		var i: int = r * m.n + sol[r]
		var guard := 0
		while m.board.cells[i] != Cells.CAKE and guard < 4: m.tap_cell(r, sol[r]); guard += 1

func test_ch8_to_all_baked_once_then_home():
	var m = await _main_all_but_last()
	assert_eq(m.mode, "chapter")
	_solve(m); m._after_card()
	assert_eq(m.screen, "chapter_end")
	assert_false(m.end_next.visible, "no Next chapter after ch8")
	await m.chapter_end_continue("home")
	assert_eq(m.screen, "all_baked")
	assert_true(m.progress.all_baked_seen)
	assert_eq(m.all_shelf.owned.size(), 8)
	var line = m.all_screen.find_child("AllLine", true, false)
	assert_eq(line.text, "New trays every day in Bake of the Day.")
	m.show_home()
	assert_eq(m.screen, "home")
	assert_eq(m.home_daily.theme_type_variation, "PrimaryButton")
	assert_true(m.home_levels.visible); assert_false(m.home_continue.visible)
	assert_eq(m.progress.boot_target(), "home", "all done boots to Home")
	# replay: no unlock, no chapter-end screen
	var rec: int = m.progress.recipes.size()
	var cc: int = m.ad_policy.chapters_completed
	m.show_level_map(); assert_eq(m.screen, "level_map")
	assert_true(m.replay_board("c8-b12")); await wait_frames(2)
	assert_eq(m.mode, "replay")
	_solve(m); m._after_card()
	assert_ne(m.screen, "chapter_end"); assert_ne(m.screen, "all_baked")
	assert_eq(m.progress.recipes.size(), rec); assert_eq(m.ad_policy.chapters_completed, cc)

func test_level_map_lists_96_with_locks():
	var m = await _main_all_but_last()
	m.progress.solved.erase("c8-b11")
	m.show_level_map(); assert_eq(m.screen, "level_map")
	assert_eq(m.map_buttons.size(), 96)
	var n := 0
	for ch in range(1, 9): n += m.map_box.get_node("MapGrid%d" % ch).get_child_count()
	assert_eq(n, 96)
	assert_false(m.map_buttons["c8-b11"].disabled, "first unsolved level is open")
	assert_eq(m.map_buttons["c8-b11"].theme_type_variation, "PrimaryButton", "next level highlighted")
	assert_true(m.map_buttons["c8-b12"].disabled, "later unsolved level locked")
	assert_false(m.map_buttons["c1-b1"].disabled, "solved level replayable")
	assert_false(m.open_level("c8-b12"), "locked level refused")
	assert_true(m.open_level("c8-b11")); await wait_frames(2)
	assert_eq(m.mode, "chapter"); assert_eq(m.label.text, "Level 95")
	m.show_level_map()
	assert_true(m.open_level("c1-b3")); await wait_frames(2)
	assert_eq(m.mode, "replay"); assert_eq(m.label.text, "Level 3")
