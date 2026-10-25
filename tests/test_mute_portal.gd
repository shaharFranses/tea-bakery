## Portal mute (CrazyGames muteAudio, TT-AC-32) composes with tab-hide/blur/ad/user: effective mute = ANY reason.
## Neither overrides the other (MuteState + Sfx). Browser-side cases: ci/mute_smoke.py.
extends GutTest
const MuteState = preload("res://game/mute_state.gd")

func test_portal_and_hidden_independent():
	var m = MuteState.new()
	m.set_reason("portal", true); m.set_reason("hidden", true)
	assert_true(m.set_reason("hidden", false), "showing the tab must not unmute while the portal says muted")
	m.set_reason("hidden", true)
	assert_true(m.set_reason("portal", false), "portal unmute must not unmute a hidden tab")
	assert_false(m.set_reason("hidden", false), "both cleared -> sound")

func test_portal_mid_session_change():
	var m = MuteState.new()
	assert_false(m.muted())
	assert_true(m.set_reason("portal", true), "settings change -> muted")
	m.set_reason("user", true)
	assert_true(m.set_reason("portal", false), "user mute still holds")
	assert_false(m.set_reason("user", false))

func test_sfx_set_portal_muted_drives_master_bus():
	Sfx.set_reason("hidden", false); Sfx.set_reason("blur", false)
	Sfx.set_portal_muted(true)
	assert_true(AudioServer.is_bus_mute(0))
	assert_true(Sfx.state.reasons.has("portal"))
	Sfx.set_portal_muted(false)
	assert_false(Sfx.state.reasons.has("portal"))
