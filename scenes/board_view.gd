## tea-bakery board, placeholder for Art's B-revised look (SPEC v1.0 §10): soft padded tiles with gaps, NO grid lines;
## tiles of the same color region sit closer together (small gap) than tiles of different regions (wide gap), so regions
## read without border lines. Empty cake mold (player MOLD full alpha, auto MOLD_AUTO at 0.5x) = code-drawn placeholder
## until Art's sprite lands (drop it at res://assets/board/mold.png and it is used automatically).
## Input: left click / tap -> cell_tapped; right-click -> cell_right_clicked (desktop mold toggle, D-12).
extends Control

const Cells = preload("res://game/cells.gd")

signal cell_tapped(r: int, c: int)
signal cell_right_clicked(r: int, c: int)

const EMPTY := Cells.EMPTY
const MOLD := Cells.MOLD
const CAKE := Cells.CAKE
const MOLD_AUTO := Cells.MOLD_AUTO
const MOLD_SPRITE := "res://assets/board/mold.png"
const AUTO_ALPHA := 0.5                      # <= 0.6 x the player mold (TT-AC-22)
## Placeholder region palette (pastel, distinct). ART owns the final palette + patterns + CVD check.
const PATCH_COLORS := [Color("f4d6a0"), Color("f2b8b5"), Color("c9e4c5"), Color("b8d8f0"), Color("e6cdf2"),
	Color("fbe7a1"), Color("f6c9a6"), Color("cfe8e2"), Color("dcd3c4")]
const INK := Color("43283A")                 # earl-grey ink (SPEC §10 palette)
const TRAY := Color("A8A09F")                # pewter tray
const CONFLICT := Color("A61E2E")            # cherry alert

var n := 5
var regions := PackedInt32Array()
var cells := PackedInt32Array()    # stored EMPTY / MOLD / CAKE per cell
var auto := {}                     # cell index -> true: shown as MOLD_AUTO (game/cells.gd auto_molds)
var conflict_cells := {}           # Vector2i -> true
var won := false
var _mold_tex: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists(MOLD_SPRITE): _mold_tex = load(MOLD_SPRITE)

func setup(size: int, reg: PackedInt32Array) -> void:
	n = size; regions = reg
	cells = PackedInt32Array(); cells.resize(n * n); cells.fill(EMPTY)
	auto = {}; conflict_cells = {}; won = false
	queue_redraw()

func board_rect() -> Rect2:
	var side: float = min(size.x, size.y)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))

func cell_size() -> float:
	return board_rect().size.x / max(n, 1)

func cell_at(local: Vector2) -> Vector2i:
	var br := board_rect()
	if not br.has_point(local): return Vector2i(-1, -1)
	var cs := cell_size()
	var c := clampi(int((local.x - br.position.x) / cs), 0, n - 1)
	var r := clampi(int((local.y - br.position.y) / cs), 0, n - 1)
	return Vector2i(r, c)

func shown(i: int) -> int:
	return Cells.shown(i, cells, auto)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var rc := cell_at(e.position)
		if rc.x >= 0:
			accept_event()
			if e.button_index == MOUSE_BUTTON_RIGHT: cell_right_clicked.emit(rc.x, rc.y)
			else: cell_tapped.emit(rc.x, rc.y)

func _tile(rect: Rect2, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	var rad := int(rect.size.x * 0.22)
	sb.set_corner_radius_all(rad)
	sb.shadow_color = Color(INK, 0.18); sb.shadow_size = int(max(1.0, rect.size.x * 0.04)); sb.shadow_offset = Vector2(0, rect.size.x * 0.03)
	sb.border_width_bottom = int(max(1.0, rect.size.x * 0.04)); sb.border_color = col.darkened(0.12)   # soft padded bevel
	draw_style_box(sb, rect)

func _mold(ctr: Vector2, cs: float, alpha: float) -> void:
	if _mold_tex:
		var s := cs * 0.6
		draw_texture_rect(_mold_tex, Rect2(ctr - Vector2(s, s) / 2.0, Vector2(s, s)), false, Color(1, 1, 1, alpha))
		return
	# placeholder empty fluted cake mold: scalloped ink outline, ~60% of the cell, hollow centre
	var pts := PackedVector2Array()
	var r0 := cs * 0.27
	for k in 49:
		var a := TAU * k / 48.0
		pts.append(ctr + Vector2(cos(a), sin(a)) * (r0 + cs * 0.025 * cos(12.0 * a)))
	draw_polyline(pts, Color(INK, alpha), max(2.0, cs * 0.05), true)
	draw_arc(ctr, r0 * 0.55, 0, TAU, 32, Color(INK, 0.6 * alpha), max(1.5, cs * 0.03), true)

func _draw() -> void:
	if regions.size() != n * n: return
	var br := board_rect(); var cs := cell_size()
	var tray := StyleBoxFlat.new(); tray.bg_color = TRAY.lerp(Color("FFF8EC"), 0.55); tray.set_corner_radius_all(int(cs * 0.25))
	draw_style_box(tray, br.grow(cs * 0.06))
	var inner := cs * 0.03; var outer := cs * 0.09        # half-gaps: same region / different region
	for i in n * n:
		var r := i / n; var c := i % n
		var g := regions[i]
		var l := inner if c > 0 and regions[i - 1] == g else outer
		var rt := inner if c < n - 1 and regions[i + 1] == g else outer
		var t := inner if r > 0 and regions[i - n] == g else outer
		var b := inner if r < n - 1 and regions[i + n] == g else outer
		var rect := Rect2(br.position + Vector2(c * cs + l, r * cs + t), Vector2(cs - l - rt, cs - t - b))
		var col: Color = PATCH_COLORS[g % PATCH_COLORS.size()]
		if won: col = col.lerp(Color("EDBB80"), 0.35)
		_tile(rect, col)
		var ctr := rect.get_center()
		var st := shown(i)
		if st == MOLD: _mold(ctr, cs, 1.0)
		elif st == MOLD_AUTO: _mold(ctr, cs, AUTO_ALPHA)
		elif st == CAKE:
			var bad := conflict_cells.has(Vector2i(r, c))
			# placeholder berry cake: crust ring + cream + berry, ink outline (>=3:1 on every tile)
			draw_circle(ctr, cs * 0.37, INK)
			draw_circle(ctr, cs * 0.34, Color("b5651d"))
			draw_circle(ctr, cs * 0.26, Color("fff3e0"))
			draw_circle(ctr + Vector2(0, -cs * 0.04), cs * 0.09, CONFLICT if bad else Color("B0365A"))
			if bad:
				draw_arc(ctr, cs * 0.44, 0, TAU, 40, CONFLICT, max(3.0, cs * 0.07), true)
				var fs := int(max(12.0, cs * 0.3))
				draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x * 0.72, fs), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CONFLICT)
