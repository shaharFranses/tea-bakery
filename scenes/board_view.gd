## tea-bakery board in Art's B2 look (SPEC v1.0.1 §10; art/HANDOFF_GODOT.md P0 + P1). Colours/geometry: ArtPalette
## (ui/theme/art_palette.gd, generated). Only @2x sprites are loaded; mipmaps downscale them (linear+mipmaps filter).
## Per-cell draw order (handoff P0): tile -> region seams/rims (code) -> under-layer (overlay_solved / overlay_conflict /
## overlay_conflict_unit / overlay_hint_unit / given_plate) -> cake (cake_<piece>, 1.0 x cell, +0.02 down) or mold
## (0.70 x cell; auto-mold = same sprite at 0.5 alpha) -> over-layer (badge_conflict / badge_solved / hint target).
## Tray: 9-slice tray_frame (golden tray_frame_solved + SOLVED_TRAY_TINT when solved), grown 10 px (12 bottom).
## Cake piece per board (SPEC v1.2, D-03 revised): the chapter's cake (game/chapters.gd CAKES), chocolate on the daily,
## berry v2 on debug boards. Every cake shares the B2 ink outline + cream halo (tests/test_cake_contrast.gd).
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
const CAKE_PIECES := ["berry", "scone", "victoria", "lemon", "apricot", "bakewell", "custard", "macaron", "chocolate"]
const AUTO_ALPHA := Pal.AUTO_MOLD_ALPHA            # <= 0.6 x the player mold (TT-AC-22)
const TRAY_GROW := Vector4(10, 10, 10, 12)         # frame rect = board rect grown l/t/r/b (handoff P1)
const SPRITES := ["mold", "steam_puff", "overlay_conflict", "badge_conflict", "overlay_solved", "badge_solved",
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
var piece := "berry"              # cake sprite name for this board (cake_<piece>@2x.png)
var tex := {}                      # sprite name -> Texture2D (@2x)
var tiles: Array[Texture2D] = []
var tray_box: StyleBox
var tray_box_solved: StyleBox
var hint_phase := 0.0
## Game feel (SPEC §8): per-cell one-shot animations {i: [kind, t0_ms]}: mold_in 90 ms (0.8->1 + fade), cake_pop 150 ms
## (0->1.15->1), cake_out 100 ms (1->0), shake 200 ms (2 px wobble once when a conflict appears). Bake: cakes turn
## golden in reading order (40 ms stagger), then steam puffs rise from 3-5 cakes (0.3 cell, 900 ms).
const ANIM_MS := {"mold_in": 90, "cake_pop": 150, "cake_out": 100, "shake": 200}
var anim := {}
var bake_t0 := -1
var steam_cells: Array = []
var shakes_started := 0          # QA/debug counter
## Animation clock. In Movie Maker mode (godot --write-movie, used for the portal preview videos) frames render slower
## than real time, so the clock follows the frame counter at 60 fps; everywhere else it is the wall clock.
static var MOVIE := OS.has_feature("movie")
func now_ms() -> int: return int(Engine.get_process_frames() * 1000.0 / 60.0) if MOVIE else Time.get_ticks_msec()

func notify_change(i: int, before: int, after: int) -> void:
	if after == MOLD: anim[i] = ["mold_in", now_ms()]
	elif after == CAKE: anim[i] = ["cake_pop", now_ms()]
	elif before == CAKE: anim[i] = ["cake_out", now_ms()]
	set_process(true)

func set_conflicts(bad: Array) -> void:
	var nxt := {}
	for p in bad:
		nxt[p] = true
		if not conflict_cells.has(p):
			anim[p.x * n + p.y] = ["shake", now_ms()]; shakes_started += 1
	conflict_cells = nxt
	set_process(true)

func start_bake(seed_value: int) -> void:
	bake_t0 = now_ms()
	var cakes_i := []
	for i in n * n: if cells[i] == CAKE: cakes_i.append(i)
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var k := clampi(3 + rng.randi() % 3, 0, cakes_i.size())
	steam_cells = []
	while steam_cells.size() < k:
		var c: int = cakes_i[rng.randi() % cakes_i.size()]
		if not (c in steam_cells): steam_cells.append(c)
	set_process(true)

func stop_bake() -> void:
	bake_t0 = -1; steam_cells = []

func _anim_k(i: int) -> Array:   # [kind, 0..1 progress] or []
	if not anim.has(i): return []
	var a: Array = anim[i]
	var p := float(now_ms() - int(a[1])) / float(ANIM_MS[a[0]])
	if p >= 1.0: anim.erase(i); return []
	return [a[0], p]

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _ready() -> void:
	for s in SPRITES: tex[s] = load(DIR + s + "@2x.png")
	for c in CAKE_PIECES: tex["cake_" + c] = load(DIR + "cake_" + c + "@2x.png")
	tiles.clear()
	for i in Pal.REGION_NAMES.size(): tiles.append(load(DIR + "tile_%d_%s@2x.png" % [i, Pal.REGION_NAMES[i]]))
	tray_box = Slice.make(DIR + "tray_frame@2x.png", Vector4(32, 32, 32, 32), Vector4.ZERO)
	tray_box_solved = Slice.make(DIR + "tray_frame_solved@2x.png", Vector4(32, 32, 32, 32), Vector4.ZERO)

func _process(dt: float) -> void:
	var busy := not anim.is_empty() or (bake_t0 >= 0 and now_ms() - bake_t0 < 2200)
	if not hint_target.is_empty():
		hint_phase = fmod(hint_phase + dt / 0.9, 1.0); busy = true
	if busy: queue_redraw()

func setup(size: int, reg: PackedInt32Array, given_cells: Array = [], cake := "berry") -> void:
	n = size; regions = reg
	piece = cake if cake in CAKE_PIECES else "berry"
	cells = PackedInt32Array(); cells.resize(n * n); cells.fill(EMPTY)
	auto = {}; conflict_cells = {}; conflict_units = {}; hint_unit = {}; hint_target = {}; won = false
	anim = {}; stop_bake()
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
	_ranks = {}
	var rank := 0
	for j in n * n: if cells[j] == CAKE: _ranks[j] = rank; rank += 1
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
		var ak := _anim_k(i)
		var sc := 1.0; var al := 1.0
		if not ak.is_empty():
			match ak[0]:
				"mold_in": sc = lerpf(0.8, 1.0, ak[1]); al = ak[1]
				"cake_pop": sc = lerpf(0.0, 1.15, ak[1] / 0.7) if ak[1] < 0.7 else lerpf(1.15, 1.0, (ak[1] - 0.7) / 0.3)
				"shake": ctr.x += 2.0 * sin(ak[1] * TAU * 2.0)
		if st == MOLD: _sprite("mold", _centred(ctr, mold_side(cs) * sc), al)
		elif st == MOLD_AUTO: _sprite("mold", _centred(ctr, mold_side(cs) * sc), AUTO_ALPHA * al)
		elif st == EMPTY and not ak.is_empty() and ak[0] == "cake_out":
			_sprite("cake_" + piece, _centred(ctr + Vector2(0, cs * 0.02), cake_side(cs) * (1.0 - ak[1])))
		elif st == CAKE:
			var golden := won and bake_t0 >= 0 and now_ms() - bake_t0 >= _reading_rank(i) * 40
			var mod := Color(1.0, 0.86, 0.6) if golden or (won and bake_t0 < 0) else Color.WHITE
			var t2: Texture2D = tex.get("cake_" + piece)
			if t2: draw_texture_rect(t2, _centred(ctr + Vector2(0, cs * 0.02), cake_side(cs) * sc), false, mod)
			if bad: _sprite("badge_conflict", t)
			elif won: _sprite("badge_solved", t)
		if hint_target.has(i):
			var k := 0.5 - 0.5 * cos(TAU * hint_phase)
			_sprite("overlay_hint_target", _centred(t.get_center(), t.size.x * (1.0 + 0.06 * k)), 1.0 - 0.4 * k)

	# steam puffs over the solved tray (drawn over the cakes, never left there: 900 ms each, staggered 120 ms)
	if won and bake_t0 >= 0:
		for k in steam_cells.size():
			var p := float(now_ms() - bake_t0 - 300 - k * 120) / 900.0
			if p < 0.0 or p > 1.0: continue
			var ci: int = steam_cells[k]
			var top := Vector2(o.x + (ci % n + 0.5) * cs, o.y + (ci / n + 0.5) * cs - cake_side(cs) * 0.37)
			var side := cs * 0.8
			_sprite("steam_puff", Rect2(top - Vector2(side / 2.0, side + p * 0.3 * cs), Vector2(side, side)), 1.0 - p)

var _ranks := {}
func _reading_rank(i: int) -> int:
	return int(_ranks.get(i, 0))
