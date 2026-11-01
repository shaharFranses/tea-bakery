## tea-bakery QA hooks H1-H4 (QA_TEST_PLAN.md §0.4). DEBUG BUILDS ONLY: debug/ is excluded from the Web Release export,
## so none of these command strings / URL flags exist in release (checked by qa/release_audit.py + ci/release_flags_smoke.py).
##  H1  PKD_QA.dump().game schema           -> state(main)
##  H2  PKD_QA.show("board:<id>" | "gen:N,seed" | "solve_next" | "solve" | "home" | "daily:YYYY-MM-DD" | "tap:r,c" | "clear" | "new")
##      + "rclick:r,c" (desktop mold toggle) | "tap_order:mold_first|cake_first" | "auto_mold:0|1" (Settings, persisted)
##  H3  ?qa=1&date=YYYY-MM-DD (local-date override) &session_offset_s=N (session clock offset)
##  BR-2 PKD_QA.set_date("YYYY-MM-DD"[ "THH:MM"]) runtime local date via main.check_day() (real rollover path);
##       PKD_QA.retry_daily() second completion attempt on today's daily -> rejected, streak unchanged (V8)
##  BR-3 PKD_QA.set_session_s(N) runtime U2 session clock; dump().ads_decisions[] = every midgame decision
##  driver: show("chapter_end:K") completes chapter K and runs the chapter-end slot decision (synthetic);
##          the real slot runs on the chapter-end screen buttons: show("end_next") / show("end_home")
##  thin slice: show("board:cN-bM" | "home" | "recipe_book" | "skip" | "hint" | "hint_watch" | "hint_no" | "undo" |
##          "reset" | "settings" | "settings_close" | "continue")
##  H4  ?qa=1&ads=mock_available|mock_unavailable|mock_error|mock_timeout (Ads mock mode; mock has a 0.6 s ad delay)
## Not implemented yet: daily pool (step 3), "Show me".
extends RefCounted

const Gen = preload("res://game/generator.gd")
const Cfg = preload("res://game/tt_config.gd")
const Clock = preload("res://game/clock.gd")
const Cells = preload("res://game/cells.gd")

static func apply_url(params: Dictionary) -> void:
	if params.has("ads"): Ads.set_mode(str(params["ads"]))                 # H4
	if params.has("session_offset_s"):                                                                 # H3
		Dbg.clock_offset_ms = int(params["session_offset_s"]) * 1000
		Clock.add_session_offset_ms(int(params["session_offset_s"]) * 1000)
	if params.has("date"): Clock.set_local_now(str(params["date"]) + "T12:00")                          # H3

static func qa_date(params: Dictionary) -> String:
	return Clock.local_date()

static func _cell_kind(v: int) -> String:
	return Cells.NAMES[v] if v >= 0 and v < Cells.NAMES.size() else "?"

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
	for i in main.n * main.n: cells.append(_cell_kind(b.shown(i)))
	var br: Rect2 = b.board_rect()
	var gp: Vector2 = b.global_position
	var hooks = Dbg.hooks
	var params: Dictionary = hooks.params if hooks else {}
	var sm: Dictionary = main.daily.summary(Clock.local_date())
	return {"screen": main.screen, "screen_log": main.screen_log, "chapter": main.chapter, "board_no": main.board_no,
		"givens": main.givens.keys().map(func(i): return [i / main.n, i % main.n]), "card_open": main.card_open, "t_solved_ms": main.t_solved_ms, "t_interactive_ms": main.t_interactive_ms, "interactive": main.interactive,
		"progress": main.progress.to_dict(), "save_writes": Store.save_writes, "corrupt_backed_up": Store.corrupt_backed_up,
		"shakes_started": b.shakes_started, "baking": b.bake_t0 >= 0, "steam_cells": b.steam_cells.size(), "texture_id": "berry2",
		"targets": main.board.hint_target.keys().map(func(i): return [i / main.n, i % main.n]), "coach": main.puzzle.get("coach", ""),
		"bubble_text": main.hint_label.text, "dots_on": range(5).filter(func(k): return main.chapter > 0 and main.progress.is_solved("c%d-b%d" % [main.chapter, k + 1])).size(), "board_id": main.board_id(), "mode": main.mode,
		"intro_done": main.intro_done, "taps": main.taps, "n": main.n, "seed": main.seed_value, "max_size": main.max_size(),
		"tutorial": main.puzzle.get("tutorial", false), "regions": Array(main.puzzle.regions), "cells": cells,
		"cakes": main.cakes().map(func(p): return [p.x, p.y]),
		"molds": range(main.n * main.n).filter(func(i): return b.cells[i] == Cells.MOLD).map(func(i): return [i / main.n, i % main.n]),
		"molds_auto": range(main.n * main.n).filter(func(i): return b.shown(i) == Cells.MOLD_AUTO).map(func(i): return [i / main.n, i % main.n]),
		"settings": main.settings.to_dict(), "analytics": Analytics.ring, "analytics_sink": Analytics.sink,
		"conflicts": b.conflict_cells.keys().map(func(p): return [p.x, p.y]), "solved": main.won, "won": main.won, "moves": main.moves,
		"undo_len": main.history.size(), "undo_hash": str(hash(main.history.back())) if not main.history.is_empty() else "", "board_rect": [(gp.x + br.position.x) * _css(main), (gp.y + br.position.y) * _css(main), br.size.x * _css(main), br.size.y * _css(main)],
		"cell_css": b.cell_size() * _css(main), "css_per_unit": _css(main), "layout": main.layout_mode_name,
		"viewport_logical": [main.get_viewport_rect().size.x, main.get_viewport_rect().size.y], "ui": _ui(main), "hint": main.hint_state, "hint_offer": main.ad_policy.hint_offer(main._hint_chapter(), "daily" if main.mode == "daily" else "chapter", Ads.available()), "timer_visible": main.card_open,
		"active_s": main.active_ms / 1000.0, "session_s": Clock.session_s(), "session_started": Clock.session_started(),
		"date": qa_date(params), "local_now": Clock.local_datetime(), "streak": sm.streak, "best_streak": sm.best_streak,
		"total_bakes": sm.total_bakes, "bakes": main.daily.bakes, "daily_open": main.daily.open_date,
		"daily_done_today": main.daily.is_done(Clock.local_date()), "last_daily": main.last_daily_result, "unlocked": {"recipes": main.progress.recipes, "decor": main.progress.decor},
		"ad_policy": {"chapters_completed": main.ad_policy.chapters_completed, "last_midgame_session_ms": main.ad_policy.last_midgame_ms},
		"save_key": Store.KEY, "ads_log": Ads.call_log, "ads_decisions": Dbg.hooks.ads_decisions if Dbg.hooks else [], "perf_marks": main.perf_marks, "ads_mode": Ads.mode, "sdk_log": Ads.sdk_log,
		"gameplay_started": main.gameplay_started, "backdrop": main.backdrop.visible, "backdrop_asset": main.backdrop.texture != null,
		"gen_ms": main.puzzle.get("ms", 0.0), "reshapes": main.puzzle.get("reshapes", 0),
		"button_rect": [main.button.get_global_rect().position.x, main.button.get_global_rect().position.y, main.button.size.x, main.button.size.y]}

## H2. Returns a short result string (also hit-logged).
static func show(main, cmd: String) -> String:
	var res := "ok"
	if cmd == "solve": main.clear_board(); main.preset("solved")
	elif cmd == "solve_next":
		# enters the next solution cake through the normal tap path (tap cycle per Settings tap order), so moves/conflicts stay real
		var sol: PackedInt32Array = main.puzzle.solution
		res = "already solved"
		for r in main.n:
			var i: int = r * main.n + sol[r]
			if main.board.cells[i] != Cells.CAKE:
				while main.board.cells[i] != Cells.CAKE: main.tap_cell(r, sol[r])
				res = "cake r%d c%d" % [r, sol[r]]; break
	elif cmd == "clear": main.clear_board()
	elif cmd == "new": main.new_board(main.n, main.fresh_seed())
	elif cmd == "home": main.show_home()
	elif cmd == "recipe_book": main.show_recipe_book()
	elif cmd == "continue": main.home_continue_pressed()
	elif cmd == "skip": main._after_card()
	elif cmd == "hint": main.request_hint(); res = main.hint_state.text if not main.reward_modal.visible else "rewarded modal"
	elif cmd == "hint_watch": main._watch_for_hint()
	elif cmd == "hint_no": main.reward_modal.visible = false
	elif cmd == "undo": main.undo()
	elif cmd == "reset": main.clear_board()
	elif cmd == "settings": main.open_settings()
	elif cmd == "settings_close": main.close_settings()
	elif cmd == "end_next": main.chapter_end_continue("next")
	elif cmd == "end_home": main.chapter_end_continue("home")
	elif cmd.begins_with("board:"):
		var id := cmd.substr(6)
		if id == "tutorial": id = "c1-b1"
		if not main.open_board(id, true): res = "unknown board %s" % id
	elif cmd.begins_with("daily:"):
		var d := cmd.substr(6)
		res = "open %s" % d if main.open_daily(d) else "refused: %s already baked (not replayable)" % d
	elif cmd.begins_with("chapter_end_screen:"):                        # layout: the real chapter-end screen for K
		main.show_chapter_end(cmd.substr(19).to_int())
	elif cmd.begins_with("chapter_end:"):                               # BR-3: completes chapter K, runs the slot decision
		var k := cmd.substr(12).to_int()
		main.ad_policy.on_chapter_completed(k)
		main.last_chapter_end = k
		res = JSON.stringify(main.chapter_end_slot(k))
	elif cmd.begins_with("gen:"):
		var p := cmd.substr(4).split(",")
		var n := p[0].to_int(); var s := p[1].to_int() if p.size() > 1 else 1
		if n > main.max_size(): res = "refused: %dx%d not offered on this device (max %d)" % [n, n, main.max_size()]
		else: main.new_board(n, s)
	elif cmd.begins_with("rclick:"):
		var q := cmd.substr(7).split(",")
		if q.size() == 2: main.right_click_cell(q[0].to_int(), q[1].to_int())
	elif cmd.begins_with("tap_order:"): main.set_tap_order(cmd.substr(10))
	elif cmd.begins_with("auto_mold:"): main.set_auto_mold(cmd.substr(10) == "1")
	elif cmd.begins_with("tap:"):
		var p := cmd.substr(4).split(",")
		if p.size() == 2: main.tap_cell(p[0].to_int(), p[1].to_int())
	else: res = "unknown command"
	Dbg.hit("QA show %s -> %s" % [cmd, res])
	if OS.has_feature("web"): JavaScriptBridge.eval("window.__pkdShow = %s;" % JSON.stringify(res))   # JS callbacks return nothing
	return res


## BR-2 (SPEC v0.3.1 §13.1): runtime local date ("YYYY-MM-DD", optional "THH:MM"), then the same day-change path a real
## midnight rollover takes (main.check_day()). Returns the new local date-time or "bad date".
static func set_date(main, d: String) -> String:
	if not Clock.set_local_now(d if "T" in d else d + "T12:00"): return "bad date"
	main.check_day()
	Dbg.hit("set_date %s" % Clock.local_datetime())
	return Clock.local_datetime()

## BR-2: second completion attempt on today's daily; rejected (counted=false) with streak/total unchanged if baked.
static func retry_daily(main) -> Dictionary:
	var r: Dictionary = main.retry_today_daily()
	Dbg.hit("retry_daily -> %s" % ("REJECTED" if not r.counted else "counted"))
	return r

## BR-3: runtime U2 session clock.
static func set_session_s(n: float) -> float:
	Clock.set_session_s(n)
	Dbg.hit("set_session_s %.3f" % Clock.session_s())
	return Clock.session_s()
