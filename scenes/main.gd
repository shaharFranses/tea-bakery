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

var intro_done := false
var n := 5
var seed_value := 1
var puzzle: Dictionary = {}
var moves := 0
var won := false
var taps := 0

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
	label = Label.new(); label.name = "Title"; label.text = "Tea Bakery"   # working title placeholder; final title TBD
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(label)
	var hint := Label.new(); hint.name = "Hint"
	hint.text = "One cake in every row, column and dough patch.\nCakes can't touch, not even at the corners."
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
	var mobile := OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") \
		or DisplayServer.is_touchscreen_available()
	if mobile: return Gen.MAX_N_MOBILE
	var side: float = board.board_rect().size.x if board and board.size.x > 0 else 0.0
	if side > 0.0 and side / 9.0 < 44.0: return Gen.MAX_N_MOBILE
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
	Store.loading_stop()      # CrazyGames loadingStop: intro finished AND scene ready
	Dbg.hit("intro finished")
	_gameplay_start()
	print("[PKD] intro finished")

## CrazyGames SDK v3 gameplayStart, once, when board 1 is playable. Guarded: PKD_CG (html/head_include.html)
## is a no-op without the SDK (localhost, Pages, QA builds), and non-web builds skip it.
func _gameplay_start() -> void:
	if gameplay_started: return
	gameplay_started = true
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.PKD_CG && window.PKD_CG.gameplay && window.PKD_CG.gameplay(true)")
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

func qa_state() -> Dictionary:
	var br: Rect2 = board.board_rect()
	var gp := board.global_position
	var marks := []
	for i in n * n:
		if board.cells[i] == BoardView.MARK: marks.append([i / n, i % n])
	return {"intro_done": intro_done, "taps": taps, "n": n, "max_size": max_size(), "tutorial": puzzle.get("tutorial", false),
		"gameplay_started": gameplay_started, "backdrop": backdrop.visible, "backdrop_asset": backdrop.texture != null, "seed": seed_value, "moves": moves, "won": won,
		"cakes": cakes().map(func(p): return [p.x, p.y]), "marks": marks,
		"conflicts": board.conflict_cells.keys().map(func(p): return [p.x, p.y]),
		"regions": Array(puzzle.regions), "gen_ms": puzzle.ms, "reshapes": puzzle.reshapes,
		"board_rect": [gp.x + br.position.x, gp.y + br.position.y, br.size.x, br.size.y],
		"button_rect": [button.get_global_rect().position.x, button.get_global_rect().position.y, button.size.x, button.size.y]}

func qa_show(cmd: String) -> void:
	if cmd == "solve": clear_board(); _qa_state_preset("solved")
	elif cmd == "clear": clear_board()
	elif cmd == "new": new_board(n, _fresh_seed())
	elif cmd.begins_with("tap:"):
		var p := cmd.substr(4).split(",")
		if p.size() == 2: tap_cell(p[0].to_int(), p[1].to_int())
