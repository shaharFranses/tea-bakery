## PKD QA hooks (debug builds only; debug/ is excluded from the Web Release preset).
## Contract (keep these names stable across games, SD-QA retro):
##   URL:  ?qa=1 enables the on-screen hitlog; any ?qa=1&key=value is readable via Dbg.toggle(key).
##         Feature-off toggles for bisecting boot issues: intro=0, audio=0 (FF retro).
##   JS:   window.PKD_QA.dump()  -> JSON string of state (also window.__pkdDump after every publish)
##         window.PKD_QA.show(screen), window.PKD_QA.hit(msg)
##   Keys: F7 = dump to console.
## Patterns from ff-r5 scripts/game_manager.gd (?qa=1 tunables + hitlog) and sudoko_dash debug/qa_hooks.gd (dump()).
extends Node

var params: Dictionary = {}
var qa_on := false
var _lines: Array[String] = []
var _label: Label
var _cbs: Array = []

func _ready() -> void:
	print("[PKD][debug] QA hooks enabled (debug build)")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		var q = str(JavaScriptBridge.eval("location.search || ''"))
		params = parse_query(q)
	qa_on = params.get("qa", "") == "1"
	if qa_on: _make_overlay()
	if OS.has_feature("web"): _bind_js()
	# ?qa=1&cgmute=1 simulates CrazyGames muteAudio=true without the SDK (TT-AC-32 QA); PKD_QA.cgmute(0|1) changes it live.
	if OS.has_feature("web") and qa_on and params.has("cgmute"):
		JavaScriptBridge.eval("window.PKD_AUDIO && window.PKD_AUDIO.setPortalMute(%s)" % ("true" if params["cgmute"] == "1" else "false"))
	publish.call_deferred()

static func parse_query(q: String) -> Dictionary:
	var out := {}
	for kv in q.trim_prefix("?").split("&", false):
		var p = kv.split("=", true, 1)
		out[p[0].uri_decode()] = p[1].uri_decode() if p.size() > 1 else ""
	return out

func param(key: String, default_value: String = "") -> String:
	# Feature-off toggles work without qa=1; every other tunable needs qa=1 (exact param, FF lesson).
	if key in ["intro", "audio"]: return params.get(key, default_value)
	return params.get(key, default_value) if qa_on else default_value

func _make_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 127
	add_child(layer)
	_label = Label.new()
	_label.name = "QaHitlog"
	_label.position = Vector2(6, 6)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_label)
	hitlog("QA on, build %s" % build_id())

func hitlog(msg: String) -> void:
	_lines.append(msg)
	if _lines.size() > 8: _lines.pop_front()
	if _label: _label.text = "\n".join(_lines)

func build_id() -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("window.__PKD_BUILD || ''")
		if v != null and str(v) != "": return str(v)
	return "local"

func state() -> Dictionary:
	var tree := get_tree()
	var cur = tree.current_scene
	var d := {
		"scene": cur.name if cur else "",
		"build": build_id(),
		"qa": qa_on,
		"params": params,
		"paused": tree.paused,
		"muted": Sfx.is_muted(),
		"mute_reasons": Sfx.state.reasons.keys(),
		"viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"insets_css": PkdView.insets_css,
		"frames": Engine.get_frames_drawn(),
		"ads_mode": Ads.mode,
		"hitlog": _lines,
	}
	if Dbg.main and Dbg.main.has_method("qa_state"): d["game"] = Dbg.main.qa_state()
	return d

func publish() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__pkdDump = %s" % JSON.stringify(JSON.stringify(state())))

func _bind_js() -> void:
	JavaScriptBridge.eval("window.PKD_QA = window.PKD_QA || {};")
	var qa = JavaScriptBridge.get_interface("window").PKD_QA
	var defs := {
		"refresh": func(_a): publish(),
		"show": func(a): if Dbg.main and Dbg.main.has_method("qa_show"): Dbg.main.qa_show(str(a[0])),
		"hit": func(a): hitlog(str(a[0])),
		"cgmute": func(a): JavaScriptBridge.eval("window.PKD_AUDIO && window.PKD_AUDIO.setPortalMute(%s)" % ("true" if str(a[0]) == "1" else "false")),
	}
	for k in defs:
		var f: Callable = defs[k]
		var cb = JavaScriptBridge.create_callback(func(args): f.call(args); publish())
		_cbs.append(cb)
		qa[k] = cb
	# dump() is synchronous from JS: refresh then return the cached string.
	JavaScriptBridge.eval("window.PKD_QA.dump = function () { window.PKD_QA.refresh(); return window.__pkdDump || '{}'; };")

func _process(_d: float) -> void:
	if Engine.get_frames_drawn() % 30 == 0: publish()

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_F7:
		print("[PKD][dump] ", JSON.stringify(state()))
