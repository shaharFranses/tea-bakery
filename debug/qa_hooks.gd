## PKD QA hooks (debug builds only; debug/ is excluded from the Web Release preset).
## Contract (keep these names stable across games, SD-QA retro):
##   URL:  ?qa=1 enables the on-screen hitlog; any ?qa=1&key=value is readable via Dbg.toggle(key).
##         Feature-off toggles for bisecting boot issues: intro=0, audio=0 (FF retro).
##   JS:   window.PKD_QA.dump()  -> JSON string of state (also window.__pkdDump after every publish)
##         window.PKD_QA.show(screen), window.PKD_QA.hit(msg)
##   Keys: F7 = dump to console.
## Patterns from ff-r5 scripts/game_manager.gd (?qa=1 tunables + hitlog) and sudoko_dash debug/qa_hooks.gd (dump()).
extends Node
const TT_GAME := "res://debug/tt_qa_game.gd"

var params: Dictionary = {}
var qa_on := false
var _lines: Array[String] = []
var _label: Label
var _cbs: Array = []

var ads_decisions: Array = []   # every midgame decision {t, session_s, origin, allowed, reason} (BR-3)

func _ready() -> void:
	print("[PKD][debug] QA hooks enabled (debug build)")
	Ads.decided.connect(func(e): ads_decisions.append(e); hitlog("ad decision %s" % JSON.stringify(e)))
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		var q = str(JavaScriptBridge.eval("location.search || ''"))
		params = parse_query(q)
	qa_on = params.get("qa", "") == "1"
	if qa_on: _make_overlay()
	if qa_on: Callable(load("res://debug/tt_qa_game.gd"), "apply_url").call_deferred(params)   # H3/H4 (tea-bakery)
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
	if Dbg.main and ResourceLoader.exists(TT_GAME): d["game"] = load(TT_GAME).state(Dbg.main)
	d["ads_decisions"] = ads_decisions      # SPEC §13.1 BR-3: PKD_QA.dump().ads_decisions[]
	if OS.has_feature("web"):               # TT-AC-53 runtime half: network calls since boot (game ones must be 0)
		var nc = JavaScriptBridge.eval("JSON.stringify(window.__pkdNet || [])")
		d["net_calls"] = JSON.parse_string(str(nc)) if nc != null else []
		d["net_calls_from_game"] = d["net_calls"].filter(func(x): return not x.get("from_sdk", false) and not x.get("engine_loader", false)).size()
	return d

func publish() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__pkdDump = %s" % JSON.stringify(JSON.stringify(state())))

func _bind_js() -> void:
	JavaScriptBridge.eval("window.PKD_QA = window.PKD_QA || {};")
	# TT-AC-53 (SPEC v1.0.1) debug runtime half: count every fetch / XHR / sendBeacon made after boot; a call whose stack
	# has no CrazyGames SDK frame is attributed to the game (must stay 0). Read via dump().net_calls.
	# SPEC v1.0.2 note: the engine loader's (index.js) same-origin fetches of our own export files are allowed
	# ("engine_loader": true, not counted); "game code" = our GDScript and JS only.
	JavaScriptBridge.eval("""(function(){ if (window.__pkdNet) return; var L = window.__pkdNet = [];
	  function rec(api, url){ var st = (new Error()).stack || ''; L.push({api: api, url: String(url).slice(0, 200), t: performance.now(),
	    from_sdk: /crazygames/i.test(st), engine_loader: loader(url, st)}); }
	  // The direct caller (frame 3: after rec + the API wrapper) must be the engine loader's own index.js code. This hook and any
	  // JavaScriptBridge.eval code run as 'eval at ... index.js' frames, so a plain '/index.js' search marked game fetches as loader ones.
	  function loader(u, st){ try { var a = new URL(String(u && u.url || u), location.href);
	    var fr = st.split('\n').filter(function (l) { return /^\s*at /.test(l); }), c = fr[2] || '';
	    return a.origin === location.origin && ['index.js', 'index.wasm', 'index.pck', 'index.side.wasm', 'index.audio.worklet.js',
	      'index.audio.position.worklet.js'].indexOf(a.pathname.split('/').pop()) >= 0 && c.indexOf('/index.js') >= 0 && c.indexOf('eval at') < 0; } catch (e) { return false; } }
	  if (window.fetch) { var f = window.fetch; window.fetch = function(u, o){ rec('fetch', u && u.url || u); return f.apply(this, arguments); }; }
	  if (navigator.sendBeacon) { var b = navigator.sendBeacon.bind(navigator); navigator.sendBeacon = function(u, d){ rec('sendBeacon', u); return b(u, d); }; }
	  var xo = XMLHttpRequest.prototype.open; XMLHttpRequest.prototype.open = function(m, u){ rec('xhr', u); return xo.apply(this, arguments); };
	})();""")
	var qa = JavaScriptBridge.get_interface("window").PKD_QA
	var defs := {
		"refresh": func(_a): publish(),
		"show": func(a): if Dbg.main and ResourceLoader.exists(TT_GAME): load(TT_GAME).show(Dbg.main, str(a[0])),
		"hit": func(a): hitlog(str(a[0])),
		# SPEC v0.3.1 §13.1 BR-2 / BR-3 (debug ?qa=1 only)
		"set_date": func(a): if Dbg.main and ResourceLoader.exists(TT_GAME): load(TT_GAME).set_date(Dbg.main, str(a[0])),
		"retry_daily": func(_a): if Dbg.main and ResourceLoader.exists(TT_GAME): load(TT_GAME).retry_daily(Dbg.main),
		"set_session_s": func(a): if ResourceLoader.exists(TT_GAME): load(TT_GAME).set_session_s(float(str(a[0]))),
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
