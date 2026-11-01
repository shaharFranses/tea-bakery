## Audio plumbing (adapted from sudoko_dash autoload/sfx.gd). Autoload "Sfx".
## Tab-hide / blur / ad / user mute ONLY mute the Master bus. It never pauses the SceneTree:
## FF's 3-week iPhone boot hang was mute-on-hide pausing the tree before the first frame (ff-retro/build.md).
## The page-level gate in html/head_include.html (PKD_AUDIO) suspends the WebAudio context itself.
extends Node

const MuteState = preload("res://game/mute_state.gd")
var state = MuteState.new()
var played: Array = []
var _players: Array = []
var _poll := 0.0
var disabled := false     # ?audio=0 feature-off toggle

const MUSIC_LOOP := "res://assets/audio/music_loop.ogg"   # §8 one calm loop (asset pending from Art/Audio)
var music_on := true
var music_player: AudioStreamPlayer

func _ready() -> void:
	disabled = Dbg.toggle("audio", "1") == "0"
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master"); AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, -12.0)
	music_player = AudioStreamPlayer.new(); music_player.name = "Music"; music_player.bus = "Music"; add_child(music_player)
	if ResourceLoader.exists(MUSIC_LOOP): music_player.stream = load(MUSIC_LOOP)
	for i in 4:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	Ads.ad_started.connect(func(): set_reason("ad", true); _js_ad(true))
	Ads.ad_finished.connect(func(): set_reason("ad", false); _js_ad(false))
	if disabled: set_reason("toggle", true)

func _js_ad(on: bool) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.PKD_AUDIO && window.PKD_AUDIO.setAd(%s)" % ("true" if on else "false"))

func set_reason(reason: String, active: bool) -> void:
	AudioServer.set_bus_mute(0, state.set_reason(reason, active))

func set_user_muted(on: bool) -> void: set_reason("user", on)
## Portal SDK mute (starter hook 89d3081 name): reason "portal".
func set_portal_muted(on: bool) -> void: set_reason("portal", on)
func is_muted() -> bool: return AudioServer.is_bus_mute(0)
## Settings "Music" (§9): mutes only the Music bus (Master mute reasons still apply on top). Starts the loop after
## the first gesture path (called from Settings / boot after the intro).
func set_music(on: bool) -> void:
	music_on = on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not on)
	if on and music_player.stream != null and not music_player.playing and not disabled: music_player.play()
	elif not on and music_player.playing: music_player.stop()
func music_state() -> Dictionary:
	return {"on": music_on, "asset": music_player.stream != null, "playing": music_player.playing}

func play(stream: AudioStream) -> void:
	if stream == null: return
	played.append(stream.resource_path)
	if played.size() > 20: played.pop_front()
	if state.muted(): return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

func _process(delta: float) -> void:
	if not OS.has_feature("web"): return
	_poll += delta
	if _poll < 0.25: return
	_poll = 0.0
	set_reason("hidden", str(JavaScriptBridge.eval("document.hidden ? 'y' : 'n'")) == "y")
	set_reason("blur", str(JavaScriptBridge.eval("window.PKD_AUDIO ? (window.PKD_AUDIO.state().focused ? 'y' : 'n') : 'u'")) == "n")
	# Portal mute (CrazyGames muteAudio, TT-AC-32; Poki/GD later): PKD_CG's settings listener sets it in PKD_AUDIO.
	# Its own reason "portal", so showing the tab never unmutes while the portal says muted, and a portal unmute
	# never unmutes a hidden tab. Without the SDK (localhost, Pages, ?qa=1 without cgmute) it stays false.
	set_portal_muted(str(JavaScriptBridge.eval("window.PKD_CG && window.PKD_CG.muted() ? 'y' : 'n'")) == "y")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED: set_reason("hidden", true)
	elif what == NOTIFICATION_APPLICATION_RESUMED: set_reason("hidden", false)
