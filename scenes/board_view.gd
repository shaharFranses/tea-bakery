## tea-bakery board in Art's B2 look (SPEC v1.0.1 §10; art/HANDOFF_GODOT.md P0 + P1). Colours/geometry: ArtPalette
## (ui/theme/art_palette.gd, generated). Only @2x sprites are loaded; mipmaps downscale them (linear+mipmaps filter).
## Per-cell draw order (handoff P0): tile -> region seams/rims (code) -> under-layer (overlay_solved / overlay_conflict /
## overlay_conflict_unit / overlay_hint_unit / given_plate) -> cake (cake_berry, 1.0 x cell, +0.02 down) or mold
## (0.70 x cell; auto-mold = same sprite at 0.5 alpha) -> over-layer (badge_conflict / badge_solved / hint target).
## Tray: 9-slice tray_frame (golden tray_frame_solved + SOLVED_TRAY_TINT when solved), grown 10 px (12 bottom).
## Berry v2 is the only cake wired in v1 (D-03); the other cake_*.png are recipe-card / post-v1 extras.
## Input: left click / tap -> cell_tapped; right-click -> cell_right_clicked (desktop mold toggle, D-12).
extends Control

const Cells = preload("res://game/cells.gd")
const Pal = preload("res://ui/theme/art_palette.gd")
const Slice = preload("res://ui/theme/slice2x.gd")

signal cell_tapped(r: int, c: int)
signal cell_right_clicked(r: int, c: int)

const EMPTY := Cells.EMPTY
const MOLD := Cells.MOLD
const CAKE := Cells.CAKE
const MOLD_AUTO := Cells.MOLD_AUTO
const DIR := "res://assets/board/"
const MOLD_SPRITE := DIR + "mold@2x.png"
const CAKE_SPRITE := DIR + "cake_berry@2x.png"     # the v1 cake (berry v2)
const AUTO_ALPHA := Pal.AUTO_MOLD_ALPHA            # <= 0.6 x the player mold (TT-AC-22)
const TRAY_GROW := Vector4(10, 10, 10, 12)         # frame rect = board rect grown l/t/r/b (handoff P1)
const SPRITES := ["mold", "cake_berry", "overlay_conflict", "badge_conflict", "overlay_solved", "badge_solved",
	"given_plate", "overlay_hint_unit", "overlay_hint_target", "overlay_conflict_unit"]

var n := 5
var regions := PackedInt32Array()
var cells := PackedInt32Array()    # stored EMPTY / MOLD / CAKE per cell
var auto := {}                     # cell index -> true: shown as MOLD_AUTO (game/cells.gd auto_molds)
var conflict_cells := {}           # Vector2i -> true
var conflict_units := {}           # cell index -> true: shared row/column/region of a conflict (D-10 unit tint)
var givens := {}                   # cell index -> true: given cake, drawn on a plate
var hint_unit := {}                # cell index -> true (hint hook, wired in the thin slice)
var hint_target := {}              # cell index -> true
var won := false
var tex := {}                      # sprite name -> Texture2D (@2x)
var tiles: Array[Texture2D] = []
var tray_box: StyleBox
var tray_box_solved: StyleBox
var hint_phase := 0.0

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _ready() -> void:
	for s in SPRITES: tex[s] = load(DIR + s + "@2x.png")
	tiles.clear()
	for i in Pal.REGION_NAMES.size(): tiles.append(load(DIR + "tile_%d_%s@2x.png" % [i, Pal.REGION_NAMES[i]]))
	tray_box = Slice.make(DIR + "tray_frame@2x.png", Vector4(32, 32, 32, 32), Vector4.ZERO)
	tray_box_solved = Slice.make(DIR + "tray_frame_solved@2x.png", Vector4(32, 32, 32, 32), Vector4.ZERO)

func _process(dt: float) -> void:
	if hint_target.is_empty(): return
	hint_phase = fmod(hint_phase + dt / 0.9, 1.0); queue_redraw()

func setup(size: int, reg: PackedInt32Array, given_cells: Array = []) -> void:
	n = size; regions = reg
	cells = PackedInt32Array(); cells.resize(n * n); cells.fill(EMPTY)
	auto = {}; conflict_cells = {}; conflict_units = {}; hint_unit = {}; hint_target = {}; won = false
	givens = {}
	for p in given_cells: givens[p.x * n + p.y] = true
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

## Mold draw size (px) for a cell pitch: MOLD_DRAW (0.70) x cell, so the visible tin is ~60% of the cell (§10).
static func mold_side(pitch: float) -> float:
	return pitch * Pal.MOLD_DRAW

static func cake_side(pitch: float) -> float:
	return pitch * Pal.CAKE_DRAW

## Tile rect for a cell: pitch x (1 - TILE_GAP), inset TILE_GAP/2 x pitch per side.
static func tile_rect(origin: Vector2, pitch: float, r: int, c: int) -> Rect2:
	var inset := pitch * Pal.TILE_GAP / 2.0
	return Rect2(origin + Vector2(c * pitch + inset, r * pitch + inset), Vector2.ONE * pitch * (1.0 - Pal.TILE_GAP))

## Shared units (row / column / region) of every conflicting pair, as cell indices (D-10 soft unit tint).
static func units_of_conflicts(size: int, reg: PackedInt32Array, bad: Array) -> Dictionary:
	var out := {}
	for a in bad.size():
		for b in range(a + 1, bad.size()):
			var p: Vector2i = bad[a]; var q: Vector2i = bad[b]
			for i in size * size:
				var r := i / size; var c := i % size
				if (p.x == q.x and r == p.x) or (p.y == q.y and c == p.y) \
					or (reg[p.x * size + p.y] == reg[q.x * size + q.y] and reg[i] == reg[p.x * size + p.y]):
					out[i] = true
	return out

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var rc := cell_at(e.position)
		if rc.x >= 0:
			accept_event()
			if e.button_index == MOUSE_BUTTON_RIGHT: cell_right_clicked.emit(rc.x, rc.y)
			else: cell_tapped.emit(rc.x, rc.y)

func _sprite(name: String, rect: Rect2, alpha := 1.0) -> void:
	var t: Texture2D = tex.get(name)
	if t: draw_texture_rect(t, rect, false, Color(1, 1, 1, alpha))

func _centred(ctr: Vector2, side: float) -> Rect2:
	return Rect2(ctr - Vector2(side, side) / 2.0, Vector2(side, side))

func _draw() -> void:
	if regions.size() != n * n: return
	var br := board_rect(); var cs := cell_size(); var o := br.position
	# tray: 9-slice frame around the board, cream lining inside (gaps between regions show TRAY_LINING)
	var fr := Rect2(br.position - Vector2(TRAY_GROW.x, TRAY_GROW.y), br.size + Vector2(TRAY_GROW.x + TRAY_GROW.z, TRAY_GROW.y + TRAY_GROW.w))
	draw_style_box(tray_box_solved if won else tray_box, fr)
	draw_rect(br, Pal.TRAY_LINING)
	var gap := cs * Pal.TILE_GAP
	var rim_w := maxf(1.0, cs * Pal.RIM_WIDTH)
	# region joins: seam between same-region neighbours; soft rim on a region's outer edges (never ink/black lines)
	for i in n * n:
		var r := i / n; var c := i % n; var g := regions[i]
		var t := tile_rect(o, cs, r, c)
		var seam: Color = Pal.REGION_SEAMS[g]
		if c < n - 1 and regions[i + 1] == g: draw_rect(Rect2(t.end.x - cs * 0.12, t.position.y, gap + cs * 0.24, t.size.y), seam)
		if r < n - 1 and regions[i + n] == g: draw_rect(Rect2(t.position.x, t.end.y - cs * 0.12, t.size.x, gap + cs * 0.24), seam)
		# 2x2 block of one region: fill the corner where the four gaps meet (no lining dot inside a region)
		if c < n - 1 and r < n - 1 and regions[i + 1] == g and regions[i + n] == g and regions[i + n + 1] == g:
			draw_rect(Rect2(t.end - Vector2.ONE * cs * 0.12, Vector2.ONE * (gap + cs * 0.24)), seam)
		var rim: Color = Pal.REGION_RIMS[g]
		var edge := t.grow(-rim_w * 0.25)
		if c == 0 or regions[i - 1] != g: draw_line(Vector2(edge.position.x, edge.position.y + cs * 0.12), Vector2(edge.position.x, edge.end.y - cs * 0.12), rim, rim_w, true)
		if c == n - 1 or regions[i + 1] != g: draw_line(Vector2(edge.end.x, edge.position.y + cs * 0.12), Vector2(edge.end.x, edge.end.y - cs * 0.12), rim, rim_w, true)
		if r == 0 or regions[i - n] != g: draw_line(Vector2(edge.position.x + cs * 0.12, edge.position.y), Vector2(edge.end.x - cs * 0.12, edge.position.y), rim, rim_w, true)
		if r == n - 1 or regions[i + n] != g: draw_line(Vector2(edge.position.x + cs * 0.12, edge.end.y), Vector2(edge.end.x - cs * 0.12, edge.end.y), rim, rim_w, true)
	for i in n * n:
		var r := i / n; var c := i % n
		var t := tile_rect(o, cs, r, c)
		draw_texture_rect(tiles[regions[i] % tiles.size()], t, false)
		if won: draw_rect(t, Pal.SOLVED_TRAY_TINT)   # golden tray: toasted-crust tint over the board, under the cakes
		var st := shown(i)
		var bad := conflict_cells.has(Vector2i(r, c))
		# under-layer (tile-rect size)
		if conflict_units.has(i): _sprite("overlay_conflict_unit", t)
		if hint_unit.has(i): _sprite("overlay_hint_unit", t)
		if st == CAKE:
			if givens.has(i): _sprite("given_plate", t)
			if bad: _sprite("overlay_conflict", t)
			elif won: _sprite("overlay_solved", t)
		var ctr := Vector2(o.x + (c + 0.5) * cs, o.y + (r + 0.5) * cs)
		if st == MOLD: _sprite("mold", _centred(ctr, mold_side(cs)))
		elif st == MOLD_AUTO: _sprite("mold", _centred(ctr, mold_side(cs)), AUTO_ALPHA)
		elif st == CAKE:
			_sprite("cake_berry", _centred(ctr + Vector2(0, cs * 0.02), cake_side(cs)))
			if bad: _sprite("badge_conflict", t)
			elif won: _sprite("badge_solved", t)
		if hint_target.has(i):
			var k := 0.5 - 0.5 * cos(TAU * hint_phase)
			_sprite("overlay_hint_target", _centred(t.get_center(), t.size.x * (1.0 + 0.06 * k)), 1.0 - 0.4 * k)
