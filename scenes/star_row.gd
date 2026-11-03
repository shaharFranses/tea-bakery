## Row of 3 drawn stars (SPEC v1.1 §3.6): filled = gold (HINT_GOLD) with an ink outline, empty = cream with a soft
## ink outline. Vector-drawn (no font glyph, no extra art), scales to its height. Never colour-only: an empty star is
## also drawn as a thinner outline.
extends Control

const Pal = preload("res://ui/theme/art_palette.gd")

var filled := 0:
	set(v): filled = clampi(v, 0, 3); queue_redraw()
var count := 3

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _star_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		var rr := r if k % 2 == 0 else r * 0.46
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts

func _draw() -> void:
	var h := size.y
	var gap := h * 0.15
	var total := count * h + (count - 1) * gap
	var x0 := (size.x - total) / 2.0
	for k in count:
		var c := Vector2(x0 + k * (h + gap) + h / 2.0, h / 2.0 + h * 0.03)
		var pts := _star_points(c, h * 0.5)
		var on := k < filled
		draw_colored_polygon(pts, Pal.HINT_GOLD if on else Pal.CLOTTED_CREAM)
		var outline := pts.duplicate(); outline.append(pts[0])
		draw_polyline(outline, Pal.EARL_GREY_INK if on else Color(Pal.EARL_GREY_INK, 0.45), maxf(1.0, h * (0.07 if on else 0.05)), true)
