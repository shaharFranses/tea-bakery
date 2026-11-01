## tea-bakery main scene (Day-0 skeleton + minimal playable board). Working name only: the title is TBD (SM 10-25).
## Board 1 = SPEC §4 tutorial board (no menu before it, SPEC §6); "New tray" = seeded generated boards.
## Mobile boards capped at 8x8 (44 px cells); 9x9 only on desktop where cells stay >= 44 px (SPEC §9 D-04).
## CrazyGames gameplayStart fires once when board 1 becomes playable (after the intro), via PKD_CG (no-op without the SDK).
## PKD intro in overlay mode (pikeydi-logo/godot/INTEGRATION.md §2A); ?intro=0 skips it.
## Debug builds: URL seed/size/state presets; dump/show commands live in debug/ (see debug/tt_qa_game.gd).
## Nothing here pauses the tree (FF boot-hang lesson).
extends Control

const PkdIntro := preload("res://pkd_intro/pkd_intro.tscn")
const Gen = preload("res://game/generator.gd")
const Rules = preload("res://game/rules.gd")
const BoardView = preload("res://scenes/board_view.gd")
const Cfg = preload("res://game/tt_config.gd")
const UiLayout = preload("res://game/ui_layout.gd")
const Clock = preload("res://game/clock.gd")
const Daily = preload("res://game/daily.gd")
const AdPolicy = preload("res://game/ad_policy.gd")
const Cells = preload("res://game/cells.gd")
const Settings = preload("res://game/settings.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const Pal = preload("res://ui/theme/art_palette.gd")

var intro_done := false
var n := 5
var seed_value := 1
var puzzle: Dictionary = {}
var moves := 0
var won := false
var taps := 0
var session_start_ms := 0
var mode := "chapter"            # chapter | free | daily
var daily = Daily.new()
var ad_policy = AdPolicy.new(0, 0)
var save_data: Dictionary = {}
var settings = Settings.new()
var order_btn: Button
var automold_btn: Button
var board_t0_ms := 0
var last_daily_result: Dictionary = {}

@onready var margin: MarginContainer = $Margin
var label: Label
var status: Label
var board: Control
var button: Button      # "New tray" (starter's 44px button contract)
var mute: Button
var size_buttons: Array = []
var backdrop: TextureRect
var backdrop_fill: ColorRect
var gameplay_started := false
const BACKDROP_LANDSCAPE := "res://assets/backdrop/backdrop_landscape.webp"   # desktop / wide
const BACKDROP_PORTRAIT := "res://assets/backdrop/backdrop_portrait.webp"     # phone Home / Recipe Book / chapter end
const PORTRAIT_BACKDROP_SCREENS := ["home", "recipe_book", "chapter_end"]
var screen := "board"           # board | home | recipe_book | chapter_end (only "board" exists before the thin slice)
var tex_landscape: Texture2D
var tex_portrait: Texture2D
var top_bar: HBoxContainer
var dots: HBoxContainer
var bubble: PanelContainer      # rules / coach bubble (coach_bubble 9-slice), 72 -> 88 px for 3 lines
var undo_btn: Button
var history: Array = []
var chapter_dots_enabled := false   # progress dots show once chapters are wired (thin slice); themed + hooked now         # undo stack of cell snapshots
var layout_mode_name := ""     # "portrait" | "wide" (game/ui_layout.gd)
var vb: VBoxContainer          # portrait column (inside $Margin)
var wide_root: Control         # wide: board left (positioned by UiLayout.wide_split), panel right
var panel: VBoxContainer
var sizes: HFlowContainer
var row: HFlowContainer
var hint_label: Label

func _ready() -> void:
	Dbg.main = self
	theme = TtTheme.build()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # @2x sprites + mipmaps (handoff import table)
	session_start_ms = int(Time.get_unix_time_from_system() * 1000.0)
	save_data = Store.load_data()
	daily.from_dict(save_data.get("daily", {}))
	settings.from_dict(save_data.get("settings", {}))
	ad_policy.chapters_completed = int(save_data.get("chapters_completed", 0))
	_build_ui()
	_relayout()
	current_date = Clock.local_date()
	var day_timer := Timer.new(); day_timer.name = "DayTimer"; day_timer.wait_time = 5.0; day_timer.autostart = true
	day_timer.timeout.connect(check_day); add_child(day_timer)
	PkdView.insets_changed.connect(_on_resized)
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_resized)
	var qs := Dbg.toggle("seed", "")
	var qsize := Dbg.toggle("size", "")
	if qs != "" or qsize != "":
		n = clampi((qsize if qsize != "" else "5").to_int(), Gen.MIN_N, max_size())
		new_board(n, Gen.seed_from_string(qs) if qs != "" else _fresh_seed())
	else:
		load_tutorial()
	var st := Dbg.toggle("state", "")
	if st != "": _preset_state(st)
	Ads.hold(true)            # no SDK call / ad until the intro has finished (SD dev a795a1a boot hold)
	if Dbg.toggle("intro", "1") == "0":
		_on_intro_finished.call_deferred()
	else:
		var intro := PkdIntro.instantiate()
		intro.finished.connect(_on_intro_finished)
		add_child(intro)
	print("[PKD] main ready")

func _fresh_seed() -> int:
	return int(Time.get_unix_time_from_system()) & 0x7FFFFFFF

func _build_ui() -> void:
	# Landscape desktop backdrop hook (ART asset in res://assets/backdrop/, see README.txt there).
	backdrop_fill = ColorRect.new(); backdrop_fill.name = "BackdropFill"
	backdrop_fill.color = Pal.ROSEWATER_BG; backdrop_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop_fill); move_child(backdrop_fill, 1)
	backdrop = TextureRect.new(); backdrop.name = "Backdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # backdrops: lossy webp, no mipmaps
	tex_landscape = load(BACKDROP_LANDSCAPE)
	tex_portrait = load(BACKDROP_PORTRAIT)
	add_child(backdrop); move_child(backdrop, 2)
	vb = VBoxContainer.new()
	vb.name = "VBox"
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	top_bar = HBoxContainer.new(); top_bar.name = "TopBar"; top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 12)
	vb.add_child(top_bar)
	label = Label.new(); label.name = "Title"; label.text = Cfg.TITLE_PLACEHOLDER   # final title TBD
	label.theme_type_variation = "TitleLabel"   # DM Serif Display 28
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(label)
	dots = HBoxContainer.new(); dots.name = "ChapterDots"; dots.add_theme_constant_override("separation", 6)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in 5:
		var d := TextureRect.new(); d.name = "Dot%d" % k; d.custom_minimum_size = Vector2(16, 16)
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dots.add_child(d)
	top_bar.add_child(dots)
	bubble = PanelContainer.new(); bubble.name = "RulesBubble"; bubble.theme_type_variation = "CoachBubble"
	bubble.custom_minimum_size.y = TtTheme.BUBBLE_MIN_H
	vb.add_child(bubble)
	var hint := Label.new(); hint.name = "Hint"; hint_label = hint
	hint.text = Cfg.RULES_TEXT
	hint.theme_type_variation = "BubbleLabel"   # D-02: rules 16 px Lexend, up to 3 lines on phones (ruling 10:19)
	hint.add_theme_font_size_override("font_size", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.max_lines_visible = 3
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint.resized.connect(_fit_bubble)
	bubble.add_child(hint)
	sizes = HFlowContainer.new(); sizes.name = "Sizes"
	sizes.alignment = FlowContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override("h_separation", 8); sizes.add_theme_constant_override("v_separation", 8)
	vb.add_child(sizes)
	for k in range(Gen.MIN_N, Gen.MAX_N + 1):
		var b := Button.new(); b.name = "Size%d" % k; b.text = "%dx%d" % [k, k]
		b.custom_minimum_size = Vector2(60, 44); b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("n", k)
		b.pressed.connect(func(): new_board(k, _fresh_seed()))
		sizes.add_child(b); size_buttons.append(b)
	board = BoardView.new(); board.name = "Board"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(UiLayout.BOARD_MIN, UiLayout.BOARD_MIN)
	board.cell_tapped.connect(tap_cell)
	board.cell_right_clicked.connect(right_click_cell)
	board.resized.connect(_update_size_buttons)
	vb.add_child(board)
	status = Label.new(); status.name = "Status"
	status.add_theme_font_size_override("font_size", 16)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(status)
	row = HFlowContainer.new(); row.name = "Buttons"
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 10); row.add_theme_constant_override("v_separation", 10)
	vb.add_child(row)
	undo_btn = _tool_button("Undo", "Undo", "undo")
	undo_btn.pressed.connect(undo)
	var clear := _tool_button("Clear", "Reset", "reset")
	clear.pressed.connect(clear_board)
	button = _tool_button("Play", "New tray", "play", "PrimaryButton")   # starter's 44px button contract
	button.pressed.connect(func(): taps += 1; new_board(n, _fresh_seed()))
	mute = Button.new(); mute.name = "Mute"; mute.toggle_mode = true; mute.theme_type_variation = "RoundButton"
	mute.custom_minimum_size = Vector2(56, 56); mute.tooltip_text = "Sound"
	mute.icon = TtTheme.icon("sound_on"); mute.expand_icon = true
	mute.toggled.connect(func(on): Sfx.set_user_muted(on); mute.icon = TtTheme.icon("sound_off" if on else "sound_on"))
	top_bar.add_child(mute)   # top-bar round icon button (btn_round, 56 px)
	order_btn = _toggle_button("TapOrder", "Cake first")
	order_btn.toggled.connect(func(on): set_tap_order(Cells.ORDER_CAKE_FIRST if on else Cells.ORDER_MOLD_FIRST))
	automold_btn = _toggle_button("AutoMolds", "Auto-molds")
	automold_btn.toggled.connect(func(on): set_auto_mold(on))
	_sync_setting_buttons()
	# wide layout containers (empty until _relayout moves the nodes in)
	wide_root = Control.new(); wide_root.name = "Wide"; wide_root.visible = false
	wide_root.set_anchors_preset(Control.PRESET_FULL_RECT); wide_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wide_root)
	panel = VBoxContainer.new(); panel.name = "Panel"
	panel.add_theme_constant_override("separation", 8)
	panel.minimum_size_changed.connect(func(): if layout_mode_name == "wide": _fit_panel.call_deferred())
	wide_root.add_child(panel)

func _tool_button(nm: String, text: String, icon_name: String, variation := "") -> Button:
	var b := Button.new(); b.name = nm; b.text = text
	b.theme_type_variation = variation
	b.icon = TtTheme.icon(icon_name, variation != "")   # cream icons on raspberry / sage, ink on cream tool buttons
	b.custom_minimum_size = Vector2(0, 48)              # spec: tool buttons >= 48 px tall
	row.add_child(b)
	return b

## Settings toggle: toggle_on / toggle_off sprite (64x36) right of the label; the label never changes.
func _toggle_button(nm: String, text: String) -> Button:
	var b := Button.new(); b.name = nm; b.text = text; b.toggle_mode = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_constant_override("icon_max_width", 48)
	b.custom_minimum_size = Vector2(0, 48)
	b.toggled.connect(func(on): b.icon = TtTheme.ui_tex("toggle_on" if on else "toggle_off"))
	b.icon = TtTheme.ui_tex("toggle_off")
	row.add_child(b)
	return b

## Rules bubble: 72 px, 88 px when the rules run to 3 lines (16 px Lexend, 20 px lines + 12/12 padding).
func _fit_bubble() -> void:
	if bubble == null: return
	var h: float = TtTheme.BUBBLE_3LINE_H if hint_label.get_line_count() >= 3 else TtTheme.BUBBLE_MIN_H
	if layout_mode_name == "wide": h = 0.0
	if bubble.custom_minimum_size.y != h: bubble.custom_minimum_size.y = h

func _sync_dots() -> void:
	if dots == null: return
	dots.visible = chapter_dots_enabled and mode == "chapter"
	var done := 1 if mode == "chapter" else 0    # board 1 of 5 (chapter progress is wired in the thin slice)
	for k in dots.get_child_count():
		(dots.get_child(k) as TextureRect).texture = TtTheme.ui_tex("progress_dot_on" if k < done else "progress_dot_off")

func new_board(size: int, s: int) -> void:
	n = clampi(size, Gen.MIN_N, max_size()); seed_value = s; mode = "free"
	_set_puzzle(Gen.generate(n, s))
	Dbg.hit("board n=%d seed=%d (%.0f ms, %d reshapes)" % [n, s, puzzle.ms, puzzle.reshapes])

func load_tutorial() -> void:
	var t := Gen.tutorial()
	n = t.n; seed_value = t.seed; mode = "chapter"
	_set_puzzle(t)
	Dbg.hit("board 1: tutorial 5x5")

## Bake of the Day for `date` (device-local; fixed when OPENED, U1/V9). Returns false if already done (not replayable).
func open_daily(date: String) -> bool:
	if not daily.open(date):
		Dbg.hit("daily %s already baked: not replayable" % date)
		return false
	var sz := 6
	_mark_transition_start()
	n = sz; seed_value = Gen.seed_from_string("daily-" + date); mode = "daily"
	_set_puzzle(Gen.generate(n, seed_value))
	Dbg.hit("daily %s open n=%d" % [date, n])
	return true

## Daily completion -> streak (U1). forced_date: QA re-fire for V8 (counts at most once per date).
func complete_daily(forced_date: String = "") -> Dictionary:
	last_daily_result = daily.complete(Clock.local_date(), forced_date)
	if last_daily_result.counted:
		Analytics.daily_complete(last_daily_result.date, n, (Time.get_ticks_msec() - board_t0_ms) / 1000.0, 0, last_daily_result.streak)
	save_data["daily"] = daily.to_dict(); Store.save(save_data)
	Dbg.hit("daily complete %s" % JSON.stringify(last_daily_result))
	return last_daily_result

func _set_puzzle(p: Dictionary) -> void:
	if intro_done: _mark_transition_start()
	puzzle = p
	board.setup(n, puzzle.regions, puzzle.get("givens", []))
	moves = 0; won = false; history.clear()
	_sync_dots()
	_update_size_buttons()
	_refresh()
	if intro_done: _board_interactive.call_deferred()

## Largest board for this device: 8 on phones/touch, 9 on desktop only if 9x9 cells stay >= 44 px.
func max_size() -> int:
	var mobile := OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")
	if OS.has_feature("web") and not mobile:
		# coarse primary pointer = phone/tablet (incl. touch emulation); fine pointer = desktop mouse/trackpad
		mobile = str(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches ? 'y' : 'n'")) == "y"
	elif not OS.has_feature("web"):
		mobile = mobile or DisplayServer.is_touchscreen_available()
	if mobile: return Gen.MAX_N_MOBILE
	var side: float = board.board_rect().size.x if board and board.size.x > 0 else 0.0
	if side > 0.0 and side / float(Gen.MAX_N) < Cfg.MIN_TAP_PX: return Gen.MAX_N_MOBILE
	return Gen.MAX_N

func _update_size_buttons() -> void:
	var mx := max_size()
	for b in size_buttons:
		b.visible = b.get_meta("n") <= mx
		b.button_pressed = b.get_meta("n") == n

## Responsive re-layout (game/ui_layout.gd): logical viewport never smaller than CSS px, portrait column or wide split.
var _in_relayout := false
func _page_css() -> Vector2:
	var w := get_window()
	var px := Vector2(w.size)
	var dpr := 1.0
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		dpr = float(v) if v != null else 1.0
	return px / maxf(dpr, 0.01)

func _relayout() -> void:
	if _in_relayout: return
	_in_relayout = true
	var css := _page_css()
	var ls := UiLayout.logical_size(css)
	var w := get_window()
	if Vector2i(ls) != w.content_scale_size: w.content_scale_size = Vector2i(ls)
	var m := UiLayout.mode(css)
	if m != layout_mode_name:
		layout_mode_name = m
		var movers := [top_bar, bubble, sizes, board, status, row]
		for c in movers: c.get_parent().remove_child(c)
		if m == "wide":
			wide_root.add_child(board)
			for c in [top_bar, bubble, sizes, status, row]: panel.add_child(c)
			board.size_flags_vertical = Control.SIZE_FILL
		else:
			for c in movers: vb.add_child(c)
			board.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.visible = m == "portrait"; wide_root.visible = m == "wide"
		Dbg.hit("layout %s css=%dx%d logical=%dx%d" % [m, css.x, css.y, ls.x, ls.y])
	if m == "wide":
		var sp := UiLayout.wide_split(get_viewport_rect().size, PkdView.safe_margins())
		board.custom_minimum_size = Vector2.ZERO
		board.position = sp.board.position; board.size = sp.board.size
		panel_rect = sp.panel
		for c in [sizes, row, status, bubble, top_bar]: c.custom_minimum_size.x = sp.panel.size.x
		_fit_panel()
		_fit_panel.call_deferred()   # flow containers report their wrapped height only after one layout pass
	else:
		board.custom_minimum_size = Vector2(UiLayout.BOARD_MIN, UiLayout.BOARD_MIN)
		for c in [sizes, row, status, bubble, top_bar]: c.custom_minimum_size.x = 0
		# portrait gaps 8/8/12; short phones take the 3rd rules line out of the gaps (4/4/8), never the board/targets
		var g := UiLayout.portrait_gap(get_viewport_rect().size.y)
		vb.add_theme_constant_override("separation", g)
	_fit_bubble()
	_in_relayout = false

var panel_rect := Rect2()
func _fit_panel() -> void:
	if layout_mode_name != "wide": return
	panel.size = Vector2(panel_rect.size.x, 0)   # shrink to content, then centre vertically in the panel column
	panel.size = Vector2(panel_rect.size.x, maxf(panel.get_combined_minimum_size().y, 0))
	panel.position = Vector2(panel_rect.position.x, panel_rect.position.y + maxf(0.0, (panel_rect.size.y - panel.size.y) / 2.0))

func _on_resized() -> void:
	_relayout()
	_apply_safe_area()
	_update_size_buttons()

func clear_board() -> void:
	_push_history()
	board.cells.fill(Cells.EMPTY); moves = 0; won = false; _refresh()

func _push_history() -> void:
	history.append(board.cells.duplicate())
	if history.size() > 200: history.pop_front()

## Undo the last tap / right-click / reset on this board (tool row).
func undo() -> void:
	if history.is_empty() or won: return
	board.cells = history.pop_back(); _refresh()

## One tap: empty -> mold -> cake -> empty, or with Settings "Tap order: cake first" empty -> cake -> mold -> empty (D-12).
func tap_cell(r: int, c: int) -> void:
	if won: return
	var i := r * n + c
	_push_history()
	board.cells[i] = Cells.next_state(board.cells[i], settings.tap_order)
	moves += 1
	_refresh()

## Desktop right-click: toggles the empty mold (empty <-> mold), never a cake (D-12).
func right_click_cell(r: int, c: int) -> void:
	if won: return
	var i := r * n + c
	_push_history()
	board.cells[i] = Cells.right_click(board.cells[i])
	moves += 1
	_refresh()

func set_tap_order(order: String) -> void:
	settings.tap_order = order; _save_settings(); _sync_setting_buttons(); _refresh()

func set_auto_mold(on: bool) -> void:
	settings.auto_mold = on; _save_settings(); _sync_setting_buttons(); _refresh()

func _save_settings() -> void:
	save_data["settings"] = settings.to_dict(); Store.save(save_data)

func _sync_setting_buttons() -> void:
	if order_btn == null: return
	var cf: bool = settings.tap_order == Cells.ORDER_CAKE_FIRST
	order_btn.set_pressed_no_signal(cf); order_btn.icon = TtTheme.ui_tex("toggle_on" if cf else "toggle_off")
	automold_btn.set_pressed_no_signal(settings.auto_mold)
	automold_btn.icon = TtTheme.ui_tex("toggle_on" if settings.auto_mold else "toggle_off")

func set_cell(r: int, c: int, v: int) -> void:
	board.cells[r * n + c] = v; _refresh()

func cakes() -> Array:
	var out := []
	for i in n * n:
		if board.cells[i] == Cells.CAKE: out.append(Vector2i(i / n, i % n))
	return out

func _refresh() -> void:
	var cs := cakes()
	var bad := Rules.conflicts(n, puzzle.regions, cs)
	board.conflict_cells = {}
	for p in bad: board.conflict_cells[p] = true
	board.conflict_units = BoardView.units_of_conflicts(n, puzzle.regions, bad)
	if undo_btn: undo_btn.disabled = history.is_empty() or won
	board.auto = Cells.auto_molds(n, puzzle.regions, board.cells, settings.auto_mold)
	var was_won := won
	won = Rules.is_solution(n, puzzle.regions, cs)
	board.won = won
	board.queue_redraw()
	if won:
		status.text = "Tray baked! Golden and perfect."
		if not was_won:
			Dbg.hit("WIN n=%d seed=%d moves=%d" % [n, seed_value, moves])
			Analytics.board_complete(board_id(), "daily" if mode == "daily" else "chapter", n, int(puzzle.get("grade", 0)),
				(Time.get_ticks_msec() - board_t0_ms) / 1000.0, 0, 0, false)
			if mode == "daily" and daily.open_date != "":
				var r := complete_daily()
				status.text = "Bake of the Day done! Streak: %d" % r.streak + ("\nA fresh streak starts today." if r.fresh_line else "")
	elif not bad.is_empty():
		status.text = "Those cakes would stick together in the oven."
	else:
		status.text = "%d x %d tray: %d of %d cakes placed. Tap: %s." % [n, n, cs.size(), n,
			"cake, mold, clear" if settings.tap_order == Cells.ORDER_CAKE_FIRST else "mold, cake, clear"]

func _preset_state(st: String) -> void:
	var sol: PackedInt32Array = puzzle.solution
	match st:
		"solved":
			for r in n: board.cells[r * n + sol[r]] = Cells.CAKE
		"almost":
			for r in n - 1: board.cells[r * n + sol[r]] = Cells.CAKE
		"conflict":
			board.cells[0] = Cells.CAKE; board.cells[n + 1] = Cells.CAKE
	_refresh()

func _on_intro_finished() -> void:
	intro_done = true
	Ads.hold(false)
	Store.loading_stop()      # CrazyGames loadingStop: intro finished AND scene ready
	Dbg.hit("intro finished")
	_gameplay_start()
	print("[PKD] intro finished")
	_mark_transition_start()
	_board_interactive.call_deferred()   # board 1 accepts input now

## CrazyGames SDK v3 gameplayStart, once, when board 1 is playable, through the Ads gate (held during the intro;
## only reaches the page in "sdk" mode, i.e. on CrazyGames hosts or ?cgsdk=1; PKD_CG itself no-ops without the SDK).
func _gameplay_start() -> void:
	if gameplay_started: return
	gameplay_started = true
	Clock.start_session()     # U2: session_s counts from the first gameplayStart of this page load
	Ads.set_context("play")   # -> Ads.sdk("gameplayStart") in sdk mode; no-op without the SDK (mock / localhost)
	Dbg.hit("gameplayStart (board 1)")

func _apply_safe_area() -> void:
	var m = PkdView.safe_margins()
	var vs := get_viewport_rect().size
	var landscape := vs.x > vs.y
	# portrait column: full width, capped at the 480 logical max (tablet portrait scales up via ui_layout)
	var side := maxf(16.0, (vs.x - UiLayout.PORTRAIT_MAX_W) / 2.0)
	margin.add_theme_constant_override("margin_top", int(16 + m[0]))
	margin.add_theme_constant_override("margin_right", int(side + m[1]))
	margin.add_theme_constant_override("margin_bottom", int(16 + m[2]))
	margin.add_theme_constant_override("margin_left", int(side + m[3]))
	_apply_backdrop(landscape)

## Backdrops (handoff P2): landscape webp on desktop / wide; portrait webp (cover-fit, anchored top) on phone Home,
## Recipe Book and chapter end; the board screen on phones keeps the flat rosewater wallpaper (calm behind the tray).
func _apply_backdrop(landscape: bool) -> void:
	if backdrop == null: return
	backdrop_fill.visible = true
	var t: Texture2D = null
	if landscape: t = tex_landscape
	elif screen in PORTRAIT_BACKDROP_SCREENS: t = tex_portrait
	backdrop.texture = t
	backdrop.visible = t != null
	if t == null: return
	var vs := get_viewport_rect().size
	if landscape:
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:   # portrait: cover-fit anchored top (overflow is cut at the bottom, never the top)
		var k := maxf(vs.x / t.get_width(), vs.y / t.get_height())
		backdrop.set_anchors_preset(Control.PRESET_TOP_LEFT)
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.position = Vector2((vs.x - t.get_width() * k) / 2.0, 0.0)
		backdrop.size = Vector2(t.get_width(), t.get_height()) * k

func set_screen(s: String) -> void:
	screen = s; _apply_safe_area()

## BR-1 (SPEC v0.3.1 §13.1; release + debug): performance.mark() for pkd:transition_start (Next / new board tapped),
## pkd:transition_end (next board drawn) and pkd:board_interactive (next board accepts input); each mark prints exactly
## one console line "pkd:perf <mark> <ms>" (ms = performance.now() at the mark, 1 decimal). No other console output.
const PERF_JS := "(function(m,d){performance.mark(m,d?{detail:d}:undefined);console.log('pkd:perf '+m+' '+performance.now().toFixed(1));})(%s,%s)"
var _transition_open := false
var perf_marks: Array = []      # [{mark, board_id}] (tests / debug dump; off-web the console line uses engine ms)

func perf_mark(m: String, detail: Dictionary = {}) -> void:
	perf_marks.append({"mark": m, "board_id": detail.get("board_id", "")})
	if OS.has_feature("web"):
		JavaScriptBridge.eval(PERF_JS % [JSON.stringify(m), JSON.stringify(detail) if not detail.is_empty() else "null"])
	else:
		print("pkd:perf %s %.1f" % [m, Time.get_ticks_usec() / 1000.0])

func _mark_transition_start() -> void:
	if _transition_open: return
	_transition_open = true
	perf_mark("pkd:transition_start")

func _board_interactive() -> void:
	await get_tree().process_frame          # the new board has been drawn and takes input from here
	if not _transition_open: return
	_transition_open = false
	var id := board_id()
	perf_mark("pkd:transition_end", {"board_id": id})
	perf_mark("pkd:board_interactive", {"board_id": id})
	board_t0_ms = Time.get_ticks_msec()
	Analytics.board_start(id, "daily" if mode == "daily" else "chapter", n, int(puzzle.get("grade", 0)), false)   # no-op sink (§12.4)

## Chapter-end midgame slot: every decision (allowed or denied, SPEC §13.1 BR-3 reason codes) is emitted on
## Ads.decided (the debug hooks record it in dump().ads_decisions[]); requests the ad only if allowed.
func chapter_end_slot(chapter: int) -> Dictionary:
	var e: Dictionary = ad_policy.decide(chapter, Clock.session_ms(), Ads.available(), "chapter_end",
		mode if mode != "free" else "chapter", Clock.session_started())
	Ads.decided.emit(e)
	if e.allowed: Ads.midgame("chapter_end")
	return e

## Local-date change (a real midnight rollover, or the debug date hook): the open daily keeps its board date (U1/V9);
## today's daily becomes available. One path for both (SPEC §13.1 BR-2).
var current_date := ""
func check_day() -> void:
	var d := Clock.local_date()
	if current_date == "": current_date = d; return
	if d == current_date: return
	var old := current_date; current_date = d
	Dbg.hit("day change %s -> %s (open daily stays %s)" % [old, d, daily.open_date])
	if not won: _refresh()

## Second completion attempt on today's daily: always rejected if already baked; streak/total unchanged (V8).
func retry_today_daily() -> Dictionary:
	return complete_daily(Clock.local_date())

## Debug hooks (dump/show) live in debug/tt_qa_game.gd and are called by debug/qa_hooks.gd with this node; nothing
## here names them, so no hook identifier ships in the release pck (QA-A13).
func board_id() -> String:
	if mode == "daily": return "daily-" + (daily.open_date if daily.open_date != "" else "done")
	return "c1-b1" if puzzle.get("tutorial", false) else "gen-%d-%d" % [n, seed_value]

func preset(st: String) -> void:
	_preset_state(st)

func fresh_seed() -> int:
	return _fresh_seed()
