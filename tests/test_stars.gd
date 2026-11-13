## SPEC v1.1 §3.6 stars (TT-AC-55): 1 = baked, 2 = no hints, 3 = no hints and no conflict shown; best result kept,
## saved per board; replays can improve but never lower; daily shows stars on the card but stores none.
extends GutTest
const Progress = preload("res://game/progress.gd")
const Chapters = preload("res://game/chapters.gd")
const Cells = preload("res://game/cells.gd")

func test_stars_rule():
	assert_eq(Progress.stars_for(0, 0), 3)
	assert_eq(Progress.stars_for(0, 2), 2)
	assert_eq(Progress.stars_for(1, 0), 1)
	assert_eq(Progress.stars_for(3, 5), 1)

func test_best_kept_and_saved():
	var p = Progress.new()
	assert_eq(p.stars_of("c1-b1"), 0, "unsolved = 0")
	p.mark_solved("c1-b1"); assert_eq(p.stars_of("c1-b1"), 1, "solved without a record (old save) = 1")
	assert_true(p.record_stars("c1-b1", 2)); assert_false(p.record_stars("c1-b1", 1), "never lowered")
	assert_true(p.record_stars("c1-b1", 3)); assert_eq(p.stars_of("c1-b1"), 3)
	p.mark_solved("c1-b2"); p.record_stars("c1-b2", 2)
	assert_eq(p.total_stars(), 5)
	assert_eq(Progress.max_stars(), 288)
	var q = Progress.new(); q.from_dict(p.to_dict())
	assert_eq(q.to_dict(), p.to_dict()); assert_eq(q.total_stars(), 5)
	var old = Progress.new(); old.from_dict({"solved": ["c1-b1"]})
	assert_eq(old.stars_of("c1-b1"), 1, "v1.0 save loads with 1 star per solved board")

func test_level_open():
	var p = Progress.new()
	assert_true(p.level_open("c1-b1")); assert_false(p.level_open("c1-b2"))
	p.mark_solved("c1-b1")
	assert_true(p.level_open("c1-b1")); assert_true(p.level_open("c1-b2")); assert_false(p.level_open("c1-b3"))

func _main(id: String) -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for b in range(1, Chapters.BOARDS + 1): m.progress.mark_solved("c1-b%d" % b)
	m.progress.unlock_chapter(1)
	m._on_intro_finished()
	m.open_board(id)
	await wait_frames(2)
	return m

func _solve(m) -> void:
	var sol: PackedInt32Array = m.puzzle.solution
	for r in m.n:
		var i: int = r * m.n + sol[r]
		var guard := 0
		while m.board.cells[i] != Cells.CAKE and guard < 4: m.tap_cell(r, sol[r]); guard += 1

func test_clean_solve_three_stars():
	var m = await _main("c2-b1")
	_solve(m)
	assert_true(m.won)
	assert_eq(m.last_stars, 3)
	assert_eq(m.progress.stars_of("c2-b1"), 3)
	assert_true(m.card_stars.visible); assert_eq(m.card_stars.filled, 3)
	assert_false(m.card_tip.visible, "no tip at 3 stars")

func test_conflict_two_stars_then_hint_one_star_replay_keeps_best():
	var m = await _main("c2-b1")
	var sol: PackedInt32Array = m.puzzle.solution
	# two cakes in row 0 -> conflict shown, then remove the wrong one
	var wrong: int = (sol[0] + 2) % m.n
	m.set_cell(0, sol[0], Cells.CAKE); m.set_cell(0, wrong, Cells.CAKE)
	assert_gt(m.conflicts_board, 0)
	m.set_cell(0, wrong, Cells.EMPTY)
	_solve(m)
	assert_eq(m.last_stars, 2); assert_eq(m.progress.stars_of("c2-b1"), 2)
	assert_true(m.card_tip.visible)
	m._after_card()
	# replay with a hint: 1 star on the card, best (2) kept
	assert_true(m.replay_board("c2-b1")); await wait_frames(2)
	assert_eq(m.mode, "replay")
	m.show_hint("free")
	_solve(m)
	assert_eq(m.last_stars, 1)
	assert_eq(m.progress.stars_of("c2-b1"), 2, "replay never lowers the best")

func test_level_title_and_dots():
	var m = await _main("c2-b2")
	assert_eq(m.label.text, "Level 14")
	assert_eq(m.dots.get_child_count(), 12)

## SPEC v1.2: the board draws the chapter's cake; the daily uses chocolate.
func test_board_cake_per_chapter_and_daily():
	var m = await _main("c2-b2")
	assert_eq(m.board.piece, "victoria")
	m.open_board("c1-b1"); await wait_frames(1)
	assert_eq(m.board.piece, "scone")
	assert_true(m.open_daily("2026-11-05")); await wait_frames(1)
	assert_eq(m.board.piece, "custard")
	m.show_level_map()
	assert_eq(m.map_box.get_node("MapHead6/MapCake6").texture.resource_path, "res://assets/board/cake_berry_top@2x.png")
