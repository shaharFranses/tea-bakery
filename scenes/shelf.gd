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
## Cake tray (home shelf only): a cream runner under the counter with one slot per chapter; each finished chapter's baked
## cake sits in its slot. Nothing overlaps the décor above. Empty slots stay empty (D-01: no silhouettes, no "?").
const TRAY_H := 34.0       # 1x px added under the 360x160 shelf art
const CAKE_SIZE := 28.0
var cake_row := false      # set by main on the home shelf
var _cake_tex := {}

func extra_h() -> float: return TRAY_H if cake_row else 0.0

func _cake(ch: int) -> Texture2D:
	if not _cake_tex.has(ch): _cake_tex[ch] = load("res://assets/board/cake_%s@2x.png" % Chapters.CAKES[ch - 1])
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
	if cake_row:
		var tray := StyleBoxFlat.new(); tray.bg_color = Color(Pal.CLOTTED_CREAM, 0.92)
		tray.set_corner_radius_all(int(14 * k)); tray.set_border_width_all(maxi(1, int(2 * k))); tray.border_color = Pal.EARL_GREY_INK
		var ty := o.y + 156.0 * k
		draw_style_box(tray, Rect2(Vector2(o.x + 12.0 * k, ty), Vector2(336, TRAY_H - 6.0) * k))
		var cs := CAKE_SIZE * k
		for ch in owned:
			if ch < 1 or ch > Chapters.CAKES.size(): continue
			var cx: float = 30.0 + (ch - 1) * 42.857      # 8 slots across the tray
			var cy := ty + ((TRAY_H - 6.0) * k - cs) / 2.0
			if ch == drop_ch: cy -= (1.0 - drop_t) * 60.0 * k
			draw_texture_rect(_cake(ch), Rect2(Vector2(o.x + cx * k - cs / 2.0, cy), Vector2(cs, cs)), false)
