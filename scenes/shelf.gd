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
const CAKE_SIZE := 38.0   # 1x px on the 360x160 shelf
## Cake x (1x px, bottom-centre): in front of, and a little right of, each décor piece; ch3 / ch6 sit in the gaps.
const CAKE_X := {1: 62.0, 2: 118.0, 3: 136.0, 4: 186.0, 5: 238.0, 6: 208.0, 7: 294.0, 8: 346.0}

func _cake_tex(ch: int) -> Texture2D:
	var key := "cake%d" % ch
	if not _tex.has(key): _tex[key] = load("res://assets/board/cake_%s@2x.png" % Chapters.CAKES[ch - 1])
	return _tex[key]

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
		if s == null or not s.has("size"): continue   # ch3/ch6 are full-shelf overlays (slots "overlay")
		var side: float = float(s.size) * k
		var bottom := o.y + 128.0 * k + side * 0.06
		var y := bottom - side
		if ch == drop_ch: y -= (1.0 - drop_t) * 80.0 * k
		draw_texture_rect(_tex[ch], Rect2(Vector2(o.x + float(s.x) * k - side / 2.0, y), Vector2(side, side)), false)
	# the baked cake of every finished chapter sits on the counter in front of its décor piece (ch3 / ch6 have no piece: their
	# cake takes the gap between neighbours); each drops in with its décor at chapter end
	for ch in owned:
		if ch < 1 or ch > Chapters.CAKES.size(): continue
		var cx: float = CAKE_X.get(ch, 0.0)
		var cside := CAKE_SIZE * k
		var cy := o.y + 128.0 * k + cside * 0.10 - cside
		if ch == drop_ch: cy -= (1.0 - drop_t) * 80.0 * k
		draw_texture_rect(_cake_tex(ch), Rect2(Vector2(o.x + cx * k - cside / 2.0, cy), Vector2(cside, cside)), false)
	if 6 in owned: draw_texture_rect(_tex.shelf_bunting_garland, full, false)
