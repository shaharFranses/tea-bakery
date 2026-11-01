## Tea-room counter shelf (Art P2): shelf_counter -> shelf_gingham_drape (ch3 owned) -> owned décor at
## assets/decor/shelf_slots.json slots (bottom-centre on y 128, baseline 0.94) -> shelf_bunting_garland (ch6 owned).
## Locked slots stay empty: no silhouettes, no "?" (D-01). Scales uniformly to its width (360x160 at 1x).
extends Control

const Chapters = preload("res://game/chapters.gd")
var owned: Array = []
var drop_ch := 0           # décor piece currently dropping in (chapter end), 0 = none
var drop_t := 1.0
var _slots := {}
var _tex := {}

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
	var k := minf(size.x / 360.0, size.y / 160.0)
	var o := Vector2((size.x - 360.0 * k) / 2.0, size.y - 160.0 * k)
	var full := Rect2(o, Vector2(360, 160) * k)
	draw_texture_rect(_tex.shelf_counter, full, false)
	if 3 in owned: draw_texture_rect(_tex.shelf_gingham_drape, full, false)
	for ch in owned:
		var s = _slots.get(str(ch))
		if s == null: continue
		var side: float = float(s.size) * k
		var bottom := o.y + 128.0 * k + side * 0.06
		var y := bottom - side
		if ch == drop_ch: y -= (1.0 - drop_t) * 80.0 * k
		draw_texture_rect(_tex[ch], Rect2(Vector2(o.x + float(s.x) * k - side / 2.0, y), Vector2(side, side)), false)
	if 6 in owned: draw_texture_rect(_tex.shelf_bunting_garland, full, false)
