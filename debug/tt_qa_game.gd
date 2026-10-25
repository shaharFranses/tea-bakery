## tea-bakery QA hooks H1-H4 (QA_TEST_PLAN.md §0.4). DEBUG BUILDS ONLY: debug/ is excluded from the Web Release export,
## so none of these command strings / URL flags exist in release (checked by qa/release_audit.py + ci/release_flags_smoke.py).
##  H1  PKD_QA.dump().game schema           -> state(main)
##  H2  PKD_QA.show("board:<id>" | "gen:N,seed" | "solve_next" | "solve" | "home" | "daily:YYYY-MM-DD" | "tap:r,c" | "clear" | "new")
##  H3  ?qa=1&date=YYYY-MM-DD (local-date override) &session_offset_s=N (session clock offset)
##  BR-2 show("now:YYYY-MM-DDTHH:MM") device-local clock at runtime, no reload; show("force_daily_complete") (V8)
##  BR-3 show("session_s:N") U2 session clock at runtime; show("chapter_end:K") runs the midgame decision (logged)
##  H4  ?qa=1&ads=mock_available|mock_unavailable|mock_error|mock_timeout (Ads mock mode; mock has a 0.6 s ad delay)
## Not implemented yet (no feature to hook): undo, hints, streak/meta, analytics ring, packs/daily, per-region texture ids.
extends RefCounted

const Gen = preload("res://game/generator.gd")
const Cfg = preload("res://game/tt_config.gd")
const Clock = preload("res://game/clock.gd")

static func apply_url(params: Dictionary) -> void:
	if params.has("ads"): Ads.set_mode(str(params["ads"]))                 # H4
	if params.has("session_offset_s"):                                                                 # H3
		Dbg.clock_offset_ms = int(params["session_offset_s"]) * 1000
		Clock.add_session_offset_ms(int(params["session_offset_s"]) * 1000)
	if params.has("date"): Clock.set_local_now(str(params["date"]) + "T12:00")                          # H3

static func qa_date(params: Dictionary) -> String:
	return Clock.local_date()

static func _cell_kind(v: int) -> String:
	return ["empty", "x_player", "cake"][v] if v >= 0 and v < 3 else "?"

## CSS px per logical unit (final canvas transform / devicePixelRatio).
static func _css(main: Control) -> float:
	var scale := main.get_viewport().get_final_transform().get_scale().x
	if OS.has_feature("web"):
		var dpr = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		return scale / float(dpr if dpr != null else 1.0)
	return scale

static func _ui(main: Control) -> Array:
	var out := []
	var stack: Array = [main]
	var css := _css(main)
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if not (n is BaseButton or n is Label): continue
		var r: Rect2 = n.get_global_rect()
		out.append({"name": str(n.name), "type": n.get_class(), "rect": [r.position.x * css, r.position.y * css, r.size.x * css, r.size.y * css],
			"font": n.get_theme_font_size("font_size") * css, "visible": n.is_visible_in_tree(),
			"enabled": not (n is BaseButton and n.disabled), "text": str(n.text)})
	return out

static func state(main) -> Dictionary:
	var b = main.board
	var cells := []
	for i in main.n * main.n: cells.append(_cell_kind(b.cells[i]))
	var br: Rect2 = b.board_rect()
	var gp: Vector2 = b.global_position
	var hooks = Dbg.hooks
	var params: Dictionary = hooks.params if hooks else {}
	var sm: Dictionary = main.daily.summary(Clock.local_date())
	return {"screen": "board", "board_id": main.board_id(), "mode": main.mode,
		"intro_done": main.intro_done, "taps": main.taps, "n": main.n, "seed": main.seed_value, "max_size": main.max_size(),
		"tutorial": main.puzzle.get("tutorial", false), "regions": Array(main.puzzle.regions), "cells": cells,
		"cakes": main.cakes().map(func(p): return [p.x, p.y]),
		"marks": range(main.n * main.n).filter(func(i): return b.cells[i] == 1).map(func(i): return [i / main.n, i % main.n]),
		"conflicts": b.conflict_cells.keys().map(func(p): return [p.x, p.y]), "solved": main.won, "won": main.won, "moves": main.moves,
		"undo_len": 0, "undo_hash": "", "board_rect": [(gp.x + br.position.x) * _css(main), (gp.y + br.position.y) * _css(main), br.size.x * _css(main), br.size.y * _css(main)],
		"cell_css": b.cell_size() * _css(main), "css_per_unit": _css(main), "layout": main.layout_mode_name,
		"viewport_logical": [main.get_viewport_rect().size.x, main.get_viewport_rect().size.y], "ui": _ui(main), "hint": null, "timer_visible": false,
		"active_s": Clock.session_s(), "session_s": Clock.session_s(), "session_started": Clock.session_started(),
		"date": qa_date(params), "local_now": Clock.local_datetime(), "streak": sm.streak, "best_streak": sm.best_streak,
		"total_bakes": sm.total_bakes, "bakes": main.daily.bakes, "daily_open": main.daily.open_date,
		"daily_done_today": main.daily.is_done(Clock.local_date()), "last_daily": main.last_daily_result, "unlocked": null,
		"ad_policy": {"chapters_completed": main.ad_policy.chapters_completed, "last_midgame_session_ms": main.ad_policy.last_midgame_ms},
		"save_key": Store.KEY, "analytics": [], "ads_log": Ads.call_log, "ads_mode": Ads.mode, "sdk_log": Ads.sdk_log,
		"gameplay_started": main.gameplay_started, "backdrop": main.backdrop.visible, "backdrop_asset": main.backdrop.texture != null,
		"gen_ms": main.puzzle.get("ms", 0.0), "reshapes": main.puzzle.get("reshapes", 0),
		"button_rect": [main.button.get_global_rect().position.x, main.button.get_global_rect().position.y, main.button.size.x, main.button.size.y]}

## H2. Returns a short result string (also hit-logged).
static func show(main, cmd: String) -> String:
	var res := "ok"
	if cmd == "solve": main.clear_board(); main.preset("solved")
	elif cmd == "solve_next":
		# enters the next solution cake through the normal tap path (empty -> X -> cake), so moves/conflicts stay real
		var sol: PackedInt32Array = main.puzzle.solution
		res = "already solved"
		for r in main.n:
			var i: int = r * main.n + sol[r]
			if main.board.cells[i] != 2:
				while main.board.cells[i] != 2: main.tap_cell(r, sol[r])
				res = "cake r%d c%d" % [r, sol[r]]; break
	elif cmd == "clear": main.clear_board()
	elif cmd == "new": main.new_board(main.n, main.fresh_seed())
	elif cmd == "home": res = "unsupported: no Home screen yet"
	elif cmd.begins_with("board:"):
		var id := cmd.substr(6)
		if id == "tutorial" or id == "c1-b1": main.load_tutorial()
		else: res = "unsupported: no chapter packs yet (%s)" % id
	elif cmd.begins_with("daily:"):
		var d := cmd.substr(6)
		res = "open %s" % d if main.open_daily(d) else "refused: %s already baked (not replayable)" % d
	elif cmd.begins_with("now:"):                                        # BR-2
		res = "now %s" % Clock.local_datetime() if Clock.set_local_now(cmd.substr(4)) else "bad datetime"
	elif cmd == "force_daily_complete":                                 # BR-2 (V8)
		var d2: String = main.daily.open_date
		if d2 == "" and main.mode == "daily" and not main.daily.bakes.is_empty(): d2 = main.daily.bakes[-1]
		if d2 == "": d2 = Clock.local_date()
		res = JSON.stringify(main.complete_daily(d2))
	elif cmd.begins_with("session_s:"):                                 # BR-3
		Clock.set_session_s(cmd.substr(10).to_float()); res = "session_s %.3f" % Clock.session_s()
	elif cmd.begins_with("chapter_end:"):                               # BR-3: completes chapter K, runs the slot decision
		var k := cmd.substr(12).to_int()
		main.ad_policy.on_chapter_completed(k)
		res = JSON.stringify(main.chapter_end_slot(k))
	elif cmd.begins_with("gen:"):
		var p := cmd.substr(4).split(",")
		var n := p[0].to_int(); var s := p[1].to_int() if p.size() > 1 else 1
		if n > main.max_size(): res = "refused: %dx%d not offered on this device (max %d)" % [n, n, main.max_size()]
		else: main.new_board(n, s)
	elif cmd.begins_with("tap:"):
		var p := cmd.substr(4).split(",")
		if p.size() == 2: main.tap_cell(p[0].to_int(), p[1].to_int())
	else: res = "unknown command"
	Dbg.hit("QA show %s -> %s" % [cmd, res])
	return res
