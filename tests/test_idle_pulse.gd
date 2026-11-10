## HN-47 / TT-AC-47: idle hint pulse after 30 s of no input, once per board, no hint consumed (S2-01, thin-07f7ba8).
## The frames below are driven by hand with a WALL step per frame (_idle_tick_ms moved back) and the clamped engine
## delta Godot really passes at low fps (0.1333 s). The old idle clock summed the engine delta and never reached 30 s.
extends GutTest
const Progress = preload("res://game/progress.gd")

func _main() -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for ch in range(1, 2): for b in range(1, 13): m.progress.mark_solved("c%d-b%d" % [ch, b])
	m.progress.unlock_chapter(1); m.progress.unlock_chapter(2)
	m._on_intro_finished()
	m.open_board("c2-b1")
	await wait_until(func(): return m.interactive, 2.0)
	m.set_process(false)            # only the hand-driven frames below advance the clocks
	return m

## n frames, each `wall_s` of real time apart, engine delta clamped like Godot's MainTimerSync (8 / 60 s).
func _frames(m, n: int, wall_s: float, engine_dt := 0.1333) -> void:
	for i in n:
		m._idle_tick_ms = Time.get_ticks_msec() - int(round(wall_s * 1000.0))
		m._process(minf(engine_dt, wall_s))

func test_pulse_fires_at_30s_wall_time_even_at_4_fps():
	var m = await _main()
	assert_true(m.interactive and not m.hint_btn.disabled, "unsolved board with Hint visible: interactive=%s disabled=%s too_small=%s screen=%s won=%s" % [m.interactive, m.hint_btn.disabled, m.too_small, m.screen, m.won])
	var free0 = m.hint_state.free_left
	_frames(m, 116, 0.25)                       # 29.0 s wall (engine delta only 15.5 s)
	assert_eq(m.hint_state.pulse_count, 0, "no pulse before 30 s")
	_frames(m, 6, 0.25)                         # 30.5 s
	assert_eq(m.hint_state.pulse_count, 1, "pulse at 30 s of WALL time (old engine-delta clock: ~16 s, no pulse)")
	assert_eq(m.hint_state.text, "", "no hint consumed"); assert_eq(m.hint_state.free_left, free0)
	_frames(m, 360, 0.25)                       # +90 s
	assert_eq(m.hint_state.pulse_count, 1, "once per board")

func test_pulse_at_60fps():
	var m = await _main()
	_frames(m, 1735, 0.017, 0.017)               # 29.5 s (17 ms frames, ~60 fps)
	assert_eq(m.hint_state.pulse_count, 0)
	_frames(m, 60, 0.017, 0.017)                 # 30.5 s
	assert_eq(m.hint_state.pulse_count, 1)

func test_input_at_25s_resets_the_timer():
	var m = await _main()
	_frames(m, 100, 0.25)                       # 25 s
	m._input_happened()
	_frames(m, 116, 0.25)                       # 54 s
	assert_eq(m.hint_state.pulse_count, 0, "timer restarted at the 25 s input")
	_frames(m, 6, 0.25)                         # 55.5 s
	assert_eq(m.hint_state.pulse_count, 1)

func test_hidden_tab_and_resume_gap_do_not_count():
	var m = await _main()
	m.page_hidden = true
	_frames(m, 160, 0.25)                       # 40 s hidden
	assert_eq(m.hint_state.pulse_count, 0, "hidden time is not idle time")
	m.page_hidden = false
	_frames(m, 1, 120.0)                        # first frame after a 2-minute background gap
	assert_almost_eq(m.idle_s, 1.0, 0.05, "one frame counts at most 1 s")

func test_next_board_starts_at_zero():
	var m = await _main()
	_frames(m, 122, 0.25)
	assert_eq(m.hint_state.pulse_count, 1)
	m.set_process(true); m.open_board("c2-b2"); await wait_until(func(): return m.interactive, 2.0); m.set_process(false)
	assert_eq(m.hint_state.pulse_count, 0); assert_lt(m.idle_s, 0.5, "idle restarts on the new board")
