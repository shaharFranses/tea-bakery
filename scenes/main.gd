## Tea & Tarts main scene (Day-0 skeleton + minimal playable board).
## PKD intro in overlay mode (pikeydi-logo/godot/INTEGRATION.md §2A); ?intro=0 skips it.
## QA (debug builds, ?qa=1): &seed=<int|text> &size=5..9 &state=solved|almost|conflict ; PKD_QA.show("solve"|"clear"|"new"|"tap:r,c").
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

func _ready() -> void:
	Dbg.main = self
	_build_ui()
	PkdView.insets_changed.connect(_apply_safe_area)
	_apply_safe_area()
	n = clampi(Dbg.toggle("size", "5").to_int(), Gen.MIN_N, Gen.MAX_N)
	var qs := Dbg.toggle("seed", "")
	seed_value = Gen.seed_from_string(qs) if qs != "" else _fresh_seed()
	new_board(n, seed_value)
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
	var vb := VBoxContainer.new()
	vb.name = "VBox"
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)
	label = Label.new(); label.name = "Title"; label.text = "Tea & Tarts"
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(label)
	var hint := Label.new(); hint.name = "Hint"
	hint.text = "One tart per row, column and dough patch. Tarts never touch, not even diagonally. Tap: X, tart, clear."
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
		b.pressed.connect(func(): new_board(k, _fresh_seed()))
		sizes.add_child(b); size_buttons.append(b)
	board = BoardView.new(); board.name = "Board"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(300, 300)
	board.cell_tapped.connect(tap_cell)
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
	n = clampi(size, Gen.MIN_N, Gen.MAX_N); seed_value = s
	puzzle = Gen.generate(n, s)
	board.setup(n, puzzle.regions)
	moves = 0; won = false
	for b in size_buttons: b.button_pressed = b.name == "Size%d" % n
	_refresh()
	Dbg.hit("board n=%d seed=%d (%.0f ms, %d reshapes)" % [n, s, puzzle.ms, puzzle.reshapes])

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
		status.text = "Those tarts would stick together."
	else:
		status.text = "%d x %d tray: %d of %d tarts placed" % [n, n, cs.size(), n]

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
	print("[PKD] intro finished")

func _apply_safe_area() -> void:
	var m = PkdView.safe_margins()
	margin.add_theme_constant_override("margin_top", int(16 + m[0]))
	margin.add_theme_constant_override("margin_right", int(16 + m[1]))
	margin.add_theme_constant_override("margin_bottom", int(16 + m[2]))
	margin.add_theme_constant_override("margin_left", int(16 + m[3]))

func qa_state() -> Dictionary:
	var br: Rect2 = board.board_rect()
	var gp := board.global_position
	var marks := []
	for i in n * n:
		if board.cells[i] == BoardView.MARK: marks.append([i / n, i % n])
	return {"intro_done": intro_done, "taps": taps, "n": n, "seed": seed_value, "moves": moves, "won": won,
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
