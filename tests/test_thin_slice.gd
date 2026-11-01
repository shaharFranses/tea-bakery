## Thin slice (step 2): progress / routing, hint text on every chapter board, solve flow, chapter end + ad slot, save.
extends GutTest

const Progress = preload("res://game/progress.gd")
const Chapters = preload("res://game/chapters.gd")
const Grader = preload("res://game/grader.gd")
const HintText = preload("res://game/hint_text.gd")
const Cells = preload("res://game/cells.gd")
const Clock = preload("res://game/clock.gd")

func _main() -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	m.ad_policy.chapters_completed = 0
	m._on_intro_finished()
	m.open_board("c1-b1")
	await wait_frames(2)
	return m

func _solve(m) -> void:
	var sol: PackedInt32Array = m.puzzle.solution
	for r in m.n:
		var i: int = r * m.n + sol[r]
		var guard := 0
		while m.board.cells[i] != Cells.CAKE and guard < 4: m.tap_cell(r, sol[r]); guard += 1

func test_progress_routing():
	var p = Progress.new()
	assert_eq(p.boot_target(), "c1-b1")
	for b in range(1, 6): p.mark_solved("c1-b%d" % b)
	assert_eq(p.next_unsolved(), "c2-b1")
	p.current_id = "c2-b3"; p.current_cells = [1]
	assert_eq(p.boot_target(), "c2-b3", "saved marks win")
	assert_true(p.unlock_chapter(1)); assert_false(p.unlock_chapter(1), "unlock once")
	var q = Progress.new(); q.from_dict(p.to_dict())
	assert_eq(q.to_dict(), p.to_dict())

func test_hint_text_every_chapter_board_ac20c():
	for ch in [1, 2]:
		for b in range(1, 6):
			var pz := Chapters.board(ch, b)
			var cakes := []
			for g in pz.givens: cakes.append(g)
			var steps := 0
			while steps < 40:
				var st := Grader.next_hint(pz.n, pz.regions, pz.solution, cakes, [])
				if st.is_empty() or not st.has("explanation"): break
				var t := HintText.text(st)
				assert_true(HintText.valid(t), "c%d-b%d: %s" % [ch, b, t])
				if st.get("place", false):
					var i: int = st.cells[0]; cakes.append(Vector2i(i / pz.n, i % pz.n))
				else: break
				steps += 1

func test_givens_immutable_and_tutorial_target():
	var m = await _main()
	assert_eq(m.screen, "board"); assert_eq(m.board_id(), "c1-b1")
	assert_false(m.givens.is_empty())
	var g: int = m.givens.keys()[0]
	m.tap_cell(g / m.n, g % m.n)
	assert_eq(m.board.cells[g], Cells.CAKE, "given unchanged")
	assert_false(m.board.hint_target.is_empty(), "tutorial target pulses")

func test_solve_flow_to_next_board():
	var m = await _main()
	_solve(m)
	assert_true(m.won, "won"); assert_true(m.card_open, "card open")
	assert_true(m.progress.is_solved("c1-b1"), "progress solved")
	m._after_card()
	await wait_until(func(): return m.interactive, 2.0)   # TT-AC-25: next board interactive <= 2.0 s
	assert_eq(m.board_id(), "c1-b2"); assert_true(m.interactive, "interactive after advance won=%s screen=%s intro=%s card=%s" % [m.won, m.screen, m.intro_done, m.card_open])
	assert_true("solve" in Store.save_writes.map(func(w): return w.reason), "solve save")

func test_conflict_shake():
	var m = await _main()
	m.new_board(5, 7)
	var s0: int = m.board.shakes_started
	m.board.cells[0] = Cells.CAKE; m.board.cells[m.n + 1] = Cells.CAKE
	m._refresh()
	assert_gt(m.board.shakes_started, s0)

func test_hints_ch1_free_ch2_rewarded():
	var m = await _main()
	m.open_board("c1-b4"); await wait_frames(2)
	m.request_hint(); m.request_hint()
	assert_false(m.reward_modal.visible, "ch1 unlimited free")
	assert_ne(m.hint_state.text, "")
	m.ad_policy.chapters_completed = 1
	var prev: String = Ads.mode
	Ads.set_mode("mock_available")
	m.open_board("c2-b1"); await wait_frames(2)
	m.request_hint()
	assert_false(m.reward_modal.visible, "first ch2 hint free")
	m.request_hint()
	assert_true(m.reward_modal.visible, "second -> rewarded confirm")
	Ads.set_mode(prev)

func test_chapter_end_unlock_and_slot():
	var m = await _main()
	for b in range(1, 5): m.progress.mark_solved("c1-b%d" % b)
	m.open_board("c1-b5"); await wait_frames(2)
	_solve(m); m._after_card()
	assert_eq(m.screen, "chapter_end")
	assert_true(1 in m.progress.recipes)
	assert_eq(m.progress.chapters_completed, 1)
	assert_true(m.end_next.visible, "ch2 available")
	Clock.set_session_s(299)
	assert_eq(m.chapter_end_slot(1).reason, "session_s<300")
	Clock.set_session_s(300)
	var e: Dictionary = m.chapter_end_slot(1)
	assert_true(e.reason in ["ok", "ad_unavailable"], e.reason)
	m.show_chapter_end(2)
	assert_true(m.end_next.visible, "ch3 follows ch2")
	m.show_chapter_end(8)
	assert_false(m.end_next.visible, "no chapter after 8 (SPEC §7.2)")

func test_home_and_book_screens():
	var m = await _main()
	m.show_home(); assert_eq(m.screen, "home"); assert_true(m.home_screen.visible)
	assert_true(m.home_daily.disabled, "daily locked before c1-b5")
	m.show_recipe_book(); assert_eq(m.screen, "recipe_book")
	assert_eq(m.book_cards.size(), 8)
