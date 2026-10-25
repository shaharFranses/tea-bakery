## tea-bakery main scene (Day-0 skeleton + minimal playable board). Working name only: the title is TBD (SM 10-25).
## Board 1 = SPEC §4 tutorial board (no menu before it, SPEC §6); "New tray" = seeded generated boards.
## Mobile boards capped at 8x8 (44 px cells); 9x9 only on desktop where cells stay >= 44 px (SPEC §9 D-04).
## CrazyGames gameplayStart fires once when board 1 becomes playable (after the intro), via PKD_CG (no-op without the SDK).
## PKD intro in overlay mode (pikeydi-logo/godot/INTEGRATION.md §2A); ?intro=0 skips it.
## QA (debug builds, ?qa=1): &seed=<int|text> (skips the tutorial) &size=5..9 &state=solved|almost|conflict ; PKD_QA.show("solve"|"clear"|"new"|"tap:r,c").
## Nothing here pauses the tree (FF boot-hang lesson).
extends Control

const PkdIntro := preload("res://pkd_intro/pkd_intro.tscn")
const Gen = preload("res://game/generator.gd")
const Rules = preload("res://game/rules.gd")
const BoardView = preload("res://scenes/board_view.gd")
const Cfg = preload("res://game/tt_config.gd")

var intro_done := false
var n := 5
var seed_value := 1
var puzzle: Dictionary = {}
var moves := 0
var won := false
var taps := 0
var session_start_ms := 0

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
const BACKDROP_PATHS := ["res://assets/backdrop/backdrop_landscape.png", "res://assets/backdrop/backdrop_landscape.webp"]
const COLUMN_MAX_W := 480.0   # portrait play column width on landscape screens

func _ready() -> void:
	Dbg.main = self
	session_start_ms = int(Time.get_unix_time_from_system() * 1000.0)
	_build_ui()
	PkdView.insets_changed.connect(_apply_safe_area)
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
	if st != "": _qa_state_preset(st)
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
	backdrop_fill.color = Color("2a2440"); backdrop_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop_fill); move_child(backdrop_fill, 1)
	backdrop = TextureRect.new(); backdrop.name = "Backdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	for path in BACKDROP_PATHS:
		if ResourceLoader.exists(path):
			backdrop.texture = load(path); break
	add_child(backdrop); move_child(backdrop, 2)
	var vb := VBoxContainer.new()
	vb.name = "VBox"
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)
	label = Label.new(); label.name = "Title"; label.text = Cfg.TITLE_PLACEHOLDER   # final title TBD
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(label)
	var hint := Label.new(); hint.name = "Hint"
	hint.text = Cfg.RULES_TEXT
	hint.add_theme_font_size_override("font_size", 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	var sizes := HBoxContainer.new(); sizes.name = "Sizes"
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override("separation", 8)
	vb.add_child(sizes)
	for k in range(Gen.MIN_N, Gen.MAX_N + 1):
		var b := Button.new(); b.name = "Size%d" % k; b.text = "%dx%d" % [k, k]
		b.custom_minimum_size = Vector2(60, 44); b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 14)
		b.set_meta("n", k)
		b.pressed.connect(func(): new_board(k, _fresh_seed()))
		sizes.add_child(b); size_buttons.append(b)
	board = BoardView.new(); board.name = "Board"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(300, 300)
	board.cell_tapped.connect(tap_cell)
	board.resized.connect(_update_size_buttons)
	vb.add_child(board)
	status = Label.new(); status.name = "Status"
	status.add_theme_font_size_override("font_size", 16)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(status)
	var row := HBoxContainer.new(); row.name = "Buttons"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	button = Button.new(); button.name = "Play"; button.text = "New tray"
	button.custom_minimum_size = Vector2(110, 48); button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(func(): taps += 1; new_board(n, _fresh_seed()))
	row.add_child(button)
	var clear := Button.new(); clear.name = "Clear"; clear.text = "Clear"
	clear.custom_minimum_size = Vector2(90, 48); clear.add_theme_font_size_override("font_size", 16)
	clear.pressed.connect(clear_board)
	row.add_child(clear)
	mute = Button.new(); mute.name = "Mute"; mute.text = "Sound: on"; mute.toggle_mode = true
	mute.custom_minimum_size = Vector2(110, 48); mute.add_theme_font_size_override("font_size", 16)
	mute.toggled.connect(func(on): Sfx.set_user_muted(on); mute.text = "Sound: off" if on else "Sound: on")
	row.add_child(mute)

func new_board(size: int, s: int) -> void:
	n = clampi(size, Gen.MIN_N, max_size()); seed_value = s
	_set_puzzle(Gen.generate(n, s))
	Dbg.hit("board n=%d seed=%d (%.0f ms, %d reshapes)" % [n, s, puzzle.ms, puzzle.reshapes])

func load_tutorial() -> void:
	var t := Gen.tutorial()
	n = t.n; seed_value = t.seed
	_set_puzzle(t)
	Dbg.hit("board 1: tutorial 5x5")

func _set_puzzle(p: Dictionary) -> void:
	puzzle = p
	board.setup(n, puzzle.regions)
	moves = 0; won = false
	_update_size_buttons()
	_refresh()

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

func _on_resized() -> void:
	_apply_safe_area()
	_update_size_buttons()

func clear_board() -> void:
	board.cells.fill(BoardView.EMPTY); moves = 0; won = false; _refresh()

func tap_cell(r: int, c: int) -> void:
	if won: return
	var i := r * n + c
	board.cells[i] = (board.cells[i] + 1) % 3     # empty -> X -> cake -> empty
	moves += 1
	_refresh()

func set_cell(r: int, c: int, v: int) -> void:
	board.cells[r * n + c] = v; _refresh()

func cakes() -> Array:
	var out := []
	for i in n * n:
		if board.cells[i] == BoardView.CAKE: out.append(Vector2i(i / n, i % n))
	return out

func _refresh() -> void:
	var cs := cakes()
	var bad := Rules.conflicts(n, puzzle.regions, cs)
	board.conflict_cells = {}
	for p in bad: board.conflict_cells[p] = true
	var was_won := won
	won = Rules.is_solution(n, puzzle.regions, cs)
	board.won = won
	board.queue_redraw()
	if won:
		status.text = "Tray baked! Golden and perfect."
		if not was_won: Dbg.hit("WIN n=%d seed=%d moves=%d" % [n, seed_value, moves])
	elif not bad.is_empty():
		status.text = "Those cakes would stick together in the oven."
	else:
		status.text = "%d x %d tray: %d of %d cakes placed. Tap: X, cake, clear." % [n, n, cs.size(), n]

func _qa_state_preset(st: String) -> void:
	var sol: PackedInt32Array = puzzle.solution
	match st:
		"solved":
			for r in n: board.cells[r * n + sol[r]] = BoardView.CAKE
		"almost":
			for r in n - 1: board.cells[r * n + sol[r]] = BoardView.CAKE
		"conflict":
			board.cells[0] = BoardView.CAKE; board.cells[n + 1] = BoardView.CAKE
	_refresh()

func _on_intro_finished() -> void:
	intro_done = true
	Ads.hold(false)
	Store.loading_stop()      # CrazyGames loadingStop: intro finished AND scene ready
	Dbg.hit("intro finished")
	_gameplay_start()
	print("[PKD] intro finished")

## CrazyGames SDK v3 gameplayStart, once, when board 1 is playable, through the Ads gate (held during the intro;
## only reaches the page in "sdk" mode, i.e. on CrazyGames hosts or ?cgsdk=1; PKD_CG itself no-ops without the SDK).
func _gameplay_start() -> void:
	if gameplay_started: return
	gameplay_started = true
	Ads.set_context("play")   # -> Ads.sdk("gameplayStart") in sdk mode; no-op without the SDK (mock / localhost)
	Dbg.hit("gameplayStart (board 1)")

func _apply_safe_area() -> void:
	var m = PkdView.safe_margins()
	var vs := get_viewport_rect().size
	var landscape := vs.x > vs.y
	# landscape: centred portrait column on the backdrop; portrait: full width
	var side := 16.0
	if landscape: side = max(16.0, (vs.x - COLUMN_MAX_W) / 2.0)
	margin.add_theme_constant_override("margin_top", int(16 + m[0]))
	margin.add_theme_constant_override("margin_right", int(side + m[1]))
	margin.add_theme_constant_override("margin_bottom", int(16 + m[2]))
	margin.add_theme_constant_override("margin_left", int(side + m[3]))
	if backdrop:
		backdrop.visible = landscape and backdrop.texture != null
		backdrop_fill.visible = landscape

## QA hooks live in debug/tt_qa_game.gd (debug export only). In release these return nothing.
const QA_GAME := "res://debug/tt_qa_game.gd"
func qa_state() -> Dictionary:
	return load(QA_GAME).state(self) if Dbg.hooks and ResourceLoader.exists(QA_GAME) else {}

func qa_show(cmd: String) -> void:
	if Dbg.hooks and ResourceLoader.exists(QA_GAME): load(QA_GAME).show(self, cmd)

func board_id() -> String:
	return "c1-b1" if puzzle.get("tutorial", false) else "gen-%d-%d" % [n, seed_value]

func preset(st: String) -> void:
	_qa_state_preset(st)

func fresh_seed() -> int:
	return _fresh_seed()
