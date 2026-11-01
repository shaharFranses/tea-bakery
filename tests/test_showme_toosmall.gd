## D-07 / HN-20 "Show me" applies the hint; TT-AC-48 too-small cover (input blocked, state kept).
extends GutTest
const Progress = preload("res://game/progress.gd")
const Cells = preload("res://game/cells.gd")
const Grader = preload("res://game/grader.gd")

func _main(id: String) -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for ch in range(1, 3): for b in range(1, 6): m.progress.mark_solved("c%d-b%d" % [ch, b])
	m._on_intro_finished()
	m.open_board(id)
	await wait_frames(3)
	return m

func test_show_me_solves_by_hints_only():
	var m = await _main("c1-b4")
	var guard := 0
	while not m.won and guard < 60:
		var st: Dictionary = m.show_hint("free")
		assert_false(st.is_empty(), "hint available at step %d" % guard)
		if st.is_empty(): break
		assert_true(m.showme_btn.visible)
		assert_true(m.apply_hint())
		assert_false(m.showme_btn.visible)
		guard += 1
	assert_true(m.won, "hint + Show me alone bakes the tray")

func test_show_me_fix_first():
	var m = await _main("c1-b4")
	var sol: PackedInt32Array = m.puzzle.solution
	var c: int = (sol[0] + 1) % m.n
	var i: int = c
	if m.givens.has(i): return
	m.board.cells[i] = Cells.CAKE; m._refresh()
	var st: Dictionary = m.show_hint("free")
	assert_eq(st.technique, "fix")
	m.apply_hint()
	assert_eq(m.board.cells[i], Cells.EMPTY, "wrong cake lifted")
	m.undo(); assert_eq(m.board.cells[i], Cells.CAKE, "Show me is one undoable move")

func test_too_small_cover_blocks_input_keeps_state():
	var m = await _main("c2-b5")
	m.tap_cell(0, 0)
	var before: Array = Array(m.board.cells).duplicate()
	m.board.custom_minimum_size = Vector2.ZERO
	m.board.size = Vector2(40.0, 40.0) * m.n / m.css_scale()
	m._check_too_small()
	assert_true(m.too_small); assert_true(m.too_small_cover.visible)
	assert_eq(m.too_small_cover.get_node("TooSmallText").text, "Turn your device upright or enlarge the window to play this tray.")
	m.tap_cell(1, 1); m.tap_cell(2, 3)
	assert_eq(Array(m.board.cells), before, "taps change nothing; state kept")
	m.board.size = Vector2(60.0, 60.0) * m.n / m.css_scale()
	m._check_too_small()
	assert_false(m.too_small); assert_false(m.too_small_cover.visible)
