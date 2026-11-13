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
## Home shelf (zigzag mode): the decor counter is NOT drawn; instead three small planks at different heights (left high,
## right middle, centre low), each carrying a different display: a tiered stand, a glass cake dome + a small plate, a
## footed plate + a flat plate. 8 slots, one per chapter. A finished chapter puts its side-view cake on its slot; the
## chapter -> slot order is a fixed scatter (mixed up, never left to right, stable between visits). Empty slots stay
## empty (D-01). The decor counter still shows on the chapter-end / all-baked shelves (zigzag = false).
const ZZ_H := 326.0        # zigzag canvas height at 1x (width 360)
var zigzag := false        # set by main on the home shelf
const PLANKS := [[6.0, 178.0, 112.0], [182.0, 354.0, 196.0], [46.0, 314.0, 292.0]]   # x0, x1, surface y
const HONEY := Color("EDBB80")
const SAGE := Color("A9C79A")
const ROSE := Color("EFA9B4")
## slot: x centre, plate-surface y, cake size (1x px)
const SLOTS := [
	[65.0, 97.0, 48.0], [119.0, 97.0, 48.0], [92.0, 58.0, 48.0],      # tiered stand: low left, low right, top
	[240.0, 194.0, 50.0], [326.0, 193.0, 42.0],                        # dome, small plate
	[92.0, 278.0, 48.0], [148.0, 278.0, 48.0], [236.0, 289.0, 50.0],   # footed plate left / right, flat plate
]
## chapter (index 0..7) -> slot index
const SLOT_OF := [3, 6, 2, 7, 0, 5, 1, 4]
var _cake_tex := {}

func extra_h() -> float: return 0.0

func _cake(ch: int) -> Texture2D:
	if not _cake_tex.has(ch): _cake_tex[ch] = load(Chapters.cake_side(Chapters.CAKES[ch - 1]))   # side view: the chapter trophy
	return _cake_tex[ch]

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
	if zigzag:
		_draw_zigzag()
		return
	var H := 160.0
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

func _ellipse(o: Vector2, c: Vector2, rx: float, ry: float, k: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24: pts.append(o + (c + Vector2(cos(i * TAU / 24.0) * rx, sin(i * TAU / 24.0) * ry)) * k)
	return pts

func _plate(o: Vector2, k: float, cx: float, y: float, w: float, col: Color, foot := true) -> void:
	var ink: Color = Pal.EARL_GREY_INK
	var lw := maxf(1.2, 1.6 * k)
	if foot:
		var f := _ellipse(o, Vector2(cx, y + 3.0), w * 0.22, 2.6, k)
		draw_colored_polygon(f, Pal.CLOTTED_CREAM); f.append(f[0]); draw_polyline(f, ink, lw, true)
	var pl := _ellipse(o, Vector2(cx, y), w / 2.0, 4.2, k)
	draw_colored_polygon(pl, col); pl.append(pl[0]); draw_polyline(pl, ink, lw, true)

func _draw_zigzag() -> void:
	var k := minf(size.x / 360.0, size.y / ZZ_H)
	var o := Vector2((size.x - 360.0 * k) / 2.0, size.y - ZZ_H * k)
	var ink: Color = Pal.EARL_GREY_INK
	var lw := maxf(1.2, 1.6 * k)
	# planks: the plank + scalloped trim strip of the counter art, each at its own height
	for pk in PLANKS:
		_plank(o, k, pk)
	# 1) tiered stand (plank 1): foot, stem, two plates
	var cx := 92.0; var by := 112.0
	var foot := _ellipse(o, Vector2(cx, by - 1.5), 20.0, 3.6, k)
	draw_colored_polygon(foot, Pal.CLOTTED_CREAM); foot.append(foot[0]); draw_polyline(foot, ink, lw, true)
	draw_line(o + Vector2(cx, by - 3.0) * k, o + Vector2(cx, by - 54.0) * k, ink, lw * 2.6)
	draw_line(o + Vector2(cx, by - 3.0) * k, o + Vector2(cx, by - 54.0) * k, Pal.CLOTTED_CREAM, lw * 1.2)
	_plate(o, k, cx, by - 15.0, 100.0, HONEY, false)
	_plate(o, k, cx, by - 54.0, 56.0, HONEY, false)
	# 2) cake dome plate + a small plate (plank 2)
	_plate(o, k, 240.0, 196.0, 96.0, Pal.CLOTTED_CREAM)
	_plate(o, k, 326.0, 196.0, 48.0, ROSE)
	# 3) footed plate + flat plate (plank 3)
	var f3 := _ellipse(o, Vector2(120.0, 290.5), 18.0, 3.2, k)
	draw_colored_polygon(f3, Pal.CLOTTED_CREAM); f3.append(f3[0]); draw_polyline(f3, ink, lw, true)
	draw_line(o + Vector2(120.0, 289.0) * k, o + Vector2(120.0, 279.0) * k, ink, lw * 2.6)
	draw_line(o + Vector2(120.0, 289.0) * k, o + Vector2(120.0, 279.0) * k, Pal.CLOTTED_CREAM, lw * 1.2)
	_plate(o, k, 120.0, 278.0, 112.0, SAGE, false)
	_plate(o, k, 236.0, 292.0, 100.0, HONEY)
	# cakes on top of the plates
	for ch in owned:
		if ch < 1 or ch > SLOT_OF.size(): continue
		var sl: Array = SLOTS[SLOT_OF[ch - 1]]
		var cs: float = float(sl[2]) * k
		var y := o.y + float(sl[1]) * k + cs * 0.06 - cs
		if ch == drop_ch: y -= (1.0 - drop_t) * 80.0 * k
		draw_texture_rect(_cake(ch), Rect2(Vector2(o.x + float(sl[0]) * k - cs / 2.0, y), Vector2(cs, cs)), false)
	# glass dome over its cake (drawn last so the cake shows through)
	var dp: PackedVector2Array = PackedVector2Array()
	for i in 21:
		var a := PI + i * PI / 20.0
		dp.append(o + (Vector2(240.0, 194.0) + Vector2(cos(a) * 44.0, sin(a) * 56.0)) * k)
	var glass := dp.duplicate()
	draw_colored_polygon(glass, Color(0.78, 0.89, 0.93, 0.38))
	draw_polyline(dp, ink, lw, true)
	draw_line(dp[0], dp[20], ink, lw)
	draw_arc(o + Vector2(240.0, 194.0) * k, 36.0 * k, deg_to_rad(205), deg_to_rad(245), 8, Color(1, 1, 1, 0.8), lw * 1.2, true)
	var knob := _ellipse(o, Vector2(240.0, 194.0 - 56.0 - 3.0), 5.0, 4.0, k)
	draw_colored_polygon(knob, HONEY); knob.append(knob[0]); draw_polyline(knob, ink, lw, true)

func _plank(o: Vector2, k: float, pk: Array) -> void:
	var w: float = pk[1] - pk[0]
	var sc := w / 360.0                       # the counter art is 360 wide; the strip keeps its aspect ratio
	draw_texture_rect_region(_tex.shelf_counter, Rect2(o + Vector2(pk[0], pk[2] - 4.5 * sc) * k, Vector2(w, 38.0 * sc) * k), Rect2(0, 244, 720, 76))
