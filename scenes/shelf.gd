## Tea-room counter shelf (Art P2): shelf_counter -> shelf_gingham_drape (ch3 owned) -> owned décor at
## assets/decor/shelf_slots.json slots (bottom-centre on y 128, baseline 0.94) -> shelf_bunting_garland (ch6 owned).
## Locked slots stay empty: no silhouettes, no "?" (D-01). Scales uniformly to its width (360x160 at 1x).
extends Control

const Chapters = preload("res://game/chapters.gd")
const Pal = preload("res://ui/theme/art_palette.gd")
var owned: Array = []
var drop_ch := 0           # décor piece currently dropping in (chapter end), 0 = none
var drop_t := 1.0
var _slots := {}
var _tex := {}
## Cake stands (home shelf only): three empty stands (two tiered, one footed plate) on a lower plank, 8 slots in all.
## A finished chapter puts its baked cake on its slot; the chapter -> slot order is a fixed scatter, so the stands fill
## in a mixed-up way (not left to right) and never move between visits. Empty slots stay empty (D-01).
const EXTRA_H := 96.0      # 1x px added under the 360x160 shelf art
const CAKE_SIZE := 31.0
const BASE_Y := 222.0      # plank top the stands stand on (1x canvas y)
## stand: x centre, plate colour, tiers [plate y offset above the base, plate width, [cake x offsets]]
const STANDS := [
	{"x": 66.0, "col": Color("EDBB80"), "tiers": [[14.0, 82.0, [-21.0, 21.0]], [40.0, 46.0, [0.0]]]},
	{"x": 180.0, "col": Color("A9C79A"), "tiers": [[14.0, 72.0, [-19.0, 19.0]], [38.0, 42.0, [0.0]]]},
	{"x": 294.0, "col": Color("EFA9B4"), "tiers": [[12.0, 86.0, [-22.0, 22.0]]]},
]
## chapter (index 0..7) -> flat slot index over STANDS (stand A: 0,1 low / 2 top, B: 3,4 / 5, C: 6,7)
const SLOT_OF := [3, 6, 2, 7, 0, 5, 1, 4]
var _cake_tex := {}

func extra_h() -> float: return EXTRA_H if cake_row else 0.0
var cake_row := false      # set by main on the home shelf

func _cake(ch: int) -> Texture2D:
	if not _cake_tex.has(ch): _cake_tex[ch] = load("res://assets/board/cake_%s@2x.png" % Chapters.CAKES[ch - 1])
	return _cake_tex[ch]

func _slot_pos(slot: int) -> Vector2:   # 1x canvas coords of the plate surface under slot's cake
	var n := 0
	for st in STANDS:
		for t in st.tiers:
			for dx in t[2]:
				if n == slot: return Vector2(float(st.x) + float(dx), BASE_Y - float(t[0]))
				n += 1
	return Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/decor/shelf_slots.json"))
	_slots = d.slots if d is Dictionary else {}
	for nm in ["shelf_counter", "shelf_gingham_drape", "shelf_bunting_garland"]: _tex[nm] = load("res://assets/decor/%s@2x.png" % nm)
	for i in 8: _tex[i + 1] = load("res://assets/decor/%s@2x.png" % Chapters.DECOR_FILES[i])

func set_owned(a: Array) -> void:
	owned = a; queue_redraw()

func drop(ch: int) -> void:
	drop_ch = ch; drop_t = 0.0
	var tw := create_tween(); tw.tween_property(self, "drop_t", 1.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.6)

func _draw() -> void:
	var H := 160.0 + extra_h()
	var k := minf(size.x / 360.0, size.y / H)
	var o := Vector2((size.x - 360.0 * k) / 2.0, size.y - H * k)
	var full := Rect2(o, Vector2(360, 160) * k)
	draw_texture_rect(_tex.shelf_counter, full, false)
	if 3 in owned: draw_texture_rect(_tex.shelf_gingham_drape, full, false)
	for ch in owned:
		var s = _slots.get(str(ch))
		if s == null or not s.has("size"): continue   # ch3/ch6 are full-shelf overlays (slots "overlay")
		var side: float = float(s.size) * k
		var bottom := o.y + 128.0 * k + side * 0.06
		var y := bottom - side
		if ch == drop_ch: y -= (1.0 - drop_t) * 80.0 * k
		draw_texture_rect(_tex[ch], Rect2(Vector2(o.x + float(s.x) * k - side / 2.0, y), Vector2(side, side)), false)
	if 6 in owned: draw_texture_rect(_tex.shelf_bunting_garland, full, false)
	if cake_row: _draw_stands(o, k)

func _ellipse(o: Vector2, c: Vector2, rx: float, ry: float, k: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24: pts.append(o + (c + Vector2(cos(i * TAU / 24.0) * rx, sin(i * TAU / 24.0) * ry)) * k)
	return pts

func _draw_stands(o: Vector2, k: float) -> void:
	var ink: Color = Pal.EARL_GREY_INK
	var lw := maxf(1.2, 1.6 * k)
	# lower plank: the bottom strip of the counter art (plank + scalloped trim), set under the stands
	var sh := 38.0
	var src := Rect2(0, 122.0 * 2.0, 720, sh * 2.0)
	draw_texture_rect_region(_tex.shelf_counter, Rect2(o + Vector2(0, (BASE_Y - 4.5) * k), Vector2(360, sh) * k), src)
	var base := o + Vector2(0, BASE_Y * k)
	for st in STANDS:
		var cx: float = st.x; var top_y := 0.0
		for t in st.tiers: top_y = maxf(top_y, float(t[0]))
		# foot, stem, then each plate (back to front)
		var foot := Vector2(cx, BASE_Y - 1.5)
		draw_colored_polygon(_ellipse(o, foot, 19.0, 3.5, k), Pal.CLOTTED_CREAM)
		var fp := _ellipse(o, foot, 19.0, 3.5, k); fp.append(fp[0]); draw_polyline(fp, ink, lw, true)
		draw_line(o + Vector2(cx, BASE_Y - 3.0) * k, o + Vector2(cx, BASE_Y - top_y) * k, ink, lw * 2.6)
		draw_line(o + Vector2(cx, BASE_Y - 3.0) * k, o + Vector2(cx, BASE_Y - top_y) * k, Pal.CLOTTED_CREAM, lw * 1.2)
		for t in st.tiers:
			var c := o + Vector2(cx, BASE_Y - float(t[0])) * k
			var rx: float = float(t[1]) / 2.0
			var pl := _ellipse(o, Vector2(cx, BASE_Y - float(t[0])), rx, 3.6, k)
			draw_colored_polygon(pl, st.col)
			var pl2 := pl.duplicate(); pl2.append(pl[0]); draw_polyline(pl2, ink, lw, true)
	# cakes last, so they sit on top of every plate
	var cs := CAKE_SIZE * k
	for ch in owned:
		if ch < 1 or ch > SLOT_OF.size(): continue
		var sp := _slot_pos(SLOT_OF[ch - 1])
		var y := o.y + (sp.y + 3.0) * k - cs
		if ch == drop_ch: y -= (1.0 - drop_t) * 60.0 * k
		draw_texture_rect(_cake(ch), Rect2(Vector2(o.x + sp.x * k - cs / 2.0, y), Vector2(cs, cs)), false)
