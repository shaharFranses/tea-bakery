## §9 Settings: Music toggle (persists), Reset progress with confirm (progress + daily cleared, settings kept).
extends GutTest
const Progress = preload("res://game/progress.gd")
const Cells = preload("res://game/cells.gd")

func _main() -> Control:
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for ch in range(1, 4): for b in range(1, 13): m.progress.mark_solved("c%d-b%d" % [ch, b])
	for ch in range(1, 4): m.progress.unlock_chapter(ch)
	m._on_intro_finished()
	m.open_board("c4-b1")
	await wait_frames(2)
	return m

func test_music_toggle_persists():
	var m = await _main()
	m.set_music(false)
	assert_false(m.settings.music); assert_false(Sfx.music_on)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert_false(m.save_data.settings.music)
	assert_false(m.music_btn.button_pressed)
	m.set_music(true); assert_true(m.save_data.settings.music)
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	m.set_sound(false); assert_false(m.save_data.settings.sound); m.set_sound(true)

func test_reset_progress_confirm_clears_progress_keeps_settings():
	var m = await _main()
	m.set_tap_order(Cells.ORDER_CAKE_FIRST)
	m.daily.bakes = ["2026-11-02"]
	m.open_settings()
	m.settings_modal.find_child("ResetProgress", true, false).emit_signal("pressed")
	assert_true(m.progress_reset_modal.visible, "confirm step first")
	assert_eq(m.progress.recipes.size(), 3, "nothing cleared before confirm")
	m.progress_reset_modal.find_child("ProgressResetCancel", true, false).emit_signal("pressed")
	assert_false(m.progress_reset_modal.visible); assert_eq(m.progress.recipes.size(), 3)
	m.progress_reset_modal.visible = true
	m.progress_reset_modal.find_child("ProgressResetOk", true, false).emit_signal("pressed")
	await wait_frames(2)
	assert_eq(m.progress.recipes, []); assert_eq(m.progress.solved, []); assert_eq(m.daily.bakes, [])
	assert_eq(m.save_data.progress.solved, []); assert_eq(m.save_data.daily.bakes, [])
	assert_eq(m.settings.tap_order, Cells.ORDER_CAKE_FIRST, "settings kept")
	assert_eq(m.save_data.settings.tap_order, Cells.ORDER_CAKE_FIRST)
	assert_eq(m.board_id(), "c1-b1"); assert_eq(m.screen, "board")
	assert_eq(Store.save_writes.back().reason, "reset_progress")
	m.set_tap_order(Cells.ORDER_MOLD_FIRST)
