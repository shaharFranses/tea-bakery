## §8 music: one calm loop (assets/audio/music_loop.ogg, synthesised by tools/make_music_loop.py), on the Music bus,
## Settings Music toggle, starts only after the first gesture, and every Master mute reason (portal muteAudio, tab
## hidden, blur, ad, Sound off) silences it. The loop-point / size check is tools/check_music_loop.py (CI step 1d).
extends GutTest

var _was_gestured := false

func before_each():
	_was_gestured = Sfx.gestured
	Sfx.gestured = false; Sfx.set_music(true)
	for r in ["portal", "hidden", "blur", "ad", "user"]: Sfx.set_reason(r, false)

func after_each():
	for r in ["portal", "hidden", "blur", "ad", "user"]: Sfx.set_reason(r, false)
	Sfx.music_player.stop(); Sfx.gestured = _was_gestured; Sfx.set_music(true)

func test_asset_is_a_looping_ogg_within_budget():
	assert_true(ResourceLoader.exists(Sfx.MUSIC_LOOP), "music_loop.ogg imported")
	var s = load(Sfx.MUSIC_LOOP)
	assert_true(s is AudioStreamOggVorbis)
	assert_true(s.loop, "loop=true (import + Sfx)")
	assert_almost_eq(s.loop_offset, 0.0, 0.0001)
	var len_s: float = s.get_length()
	assert_between(len_s, 30.0, 60.0, "30-60 s")
	var f := FileAccess.open(Sfx.MUSIC_LOOP, FileAccess.READ)
	if f != null: assert_lt(f.get_length(), 600000, "< 600 KB"); f.close()
	assert_eq(Sfx.music_player.stream, s)

func test_music_bus_routes_to_master_and_is_quieter():
	var i := AudioServer.get_bus_index("Music")
	assert_gt(i, 0); assert_eq(Sfx.music_player.bus, "Music")
	assert_eq(AudioServer.get_bus_send(i), "Master")
	assert_lt(AudioServer.get_bus_volume_db(i), -6.0, "quiet under SFX")

func test_no_music_before_first_gesture():
	Sfx.set_music(true)
	await wait_frames(2)
	assert_false(Sfx.music_player.playing, "boot / intro end never starts music without a gesture")
	var ev := InputEventMouseMotion.new(); Input.parse_input_event(ev); await wait_frames(2)
	assert_false(Sfx.gestured, "a hover is not a gesture")

func test_first_gesture_starts_music():
	var ev := InputEventScreenTouch.new(); ev.pressed = true; ev.position = Vector2(10, 10)
	Sfx._input(ev)
	assert_true(Sfx.gestured)
	assert_true(Sfx.music_player.playing, "loop starts on the first tap")
	assert_true(Sfx.music_state().playing)

func test_key_and_click_also_count_as_gesture():
	var k := InputEventKey.new(); k.pressed = true; k.keycode = KEY_SPACE
	Sfx._input(k); assert_true(Sfx.gestured)
	Sfx.gestured = false; Sfx.music_player.stop()
	var c := InputEventMouseButton.new(); c.pressed = true; c.button_index = MOUSE_BUTTON_LEFT
	Sfx._input(c); assert_true(Sfx.gestured); assert_true(Sfx.music_player.playing)

func test_music_toggle_off_stops_and_mutes_bus_on_restarts():
	Sfx.note_gesture(); assert_true(Sfx.music_player.playing)
	Sfx.set_music(false)
	assert_false(Sfx.music_player.playing); assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	Sfx.set_music(true)
	assert_true(Sfx.music_player.playing); assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))

func test_audio_off_flag_never_plays():
	Sfx.disabled = true
	Sfx.note_gesture()
	assert_false(Sfx.music_player.playing, "?audio=0")
	Sfx.disabled = false

func test_every_master_mute_reason_silences_music():
	Sfx.note_gesture()
	for r in ["portal", "hidden", "blur", "ad", "user"]:
		Sfx.set_reason(r, true)
		assert_true(AudioServer.is_bus_mute(0), "%s mutes Master (Music bus sends to Master)" % r)
		assert_true(Sfx.music_state().master_muted)
		Sfx.set_reason(r, false)
		assert_false(AudioServer.is_bus_mute(0), "%s released" % r)

func test_portal_mute_and_hidden_are_independent():
	Sfx.note_gesture()
	Sfx.set_portal_muted(true); Sfx.set_reason("hidden", true); Sfx.set_reason("hidden", false)
	assert_true(AudioServer.is_bus_mute(0), "showing the tab never unmutes while the portal says muted")
	Sfx.set_portal_muted(false)
	assert_false(AudioServer.is_bus_mute(0))
