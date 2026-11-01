## §7.2 / TT-AC-51: ch8 end -> "All recipes baked" once -> Home (Bake of the Day primary + Replay a chapter);
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
		for b in range(1, 6):
			if not (ch == 8 and b == 5): m.progress.mark_solved("c%d-b%d" % [ch, b])
		if ch < 8: m.progress.unlock_chapter(ch)
	m.ad_policy.chapters_completed = 7
	m._on_intro_finished()
	m.open_board("c8-b5")
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
	assert_true(m.home_replay.visible); assert_false(m.home_continue.visible)
	assert_eq(m.progress.boot_target(), "home", "all done boots to Home")
	# replay: no unlock, no chapter-end screen
	var rec: int = m.progress.recipes.size()
	var cc: int = m.ad_policy.chapters_completed
	m.show_chapter_list(); assert_eq(m.screen, "chapter_list")
	assert_true(m.replay_board("c8-b5")); await wait_frames(2)
	assert_eq(m.mode, "replay")
	_solve(m); m._after_card()
	assert_ne(m.screen, "chapter_end"); assert_ne(m.screen, "all_baked")
	assert_eq(m.progress.recipes.size(), rec); assert_eq(m.ad_policy.chapters_completed, cc)

func test_replay_list_lists_40():
	var m = await _main_all_but_last()
	m.show_chapter_list()
	var n := 0
	for ch in range(1, 9):
		n += m.list_box.get_node("ListRow%d" % ch).get_child_count()
	assert_eq(n, 40)
	assert_true(m.list_box.get_node("ListRow8/Replay_c8_b5").disabled, "unsolved board not replayable")
