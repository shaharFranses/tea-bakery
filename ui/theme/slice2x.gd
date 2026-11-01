## 9-slice StyleBox for Art's @2x textures (art/HANDOFF_GODOT.md: load only @2x; 9-slice margins are given at 1x).
## StyleBoxTexture draws texture margins 1:1 in canvas units, so an @2x corner would draw twice as big. This box draws
## the nine-patch at half scale over a doubled rect: corners keep their 1x logical size and stay crisp on DPR-2 screens.
class_name Slice2x
extends StyleBox

var texture: Texture2D
var margin_1x := Vector4(24, 24, 24, 24)   # left, top, right, bottom in 1x px
var modulate := Color.WHITE

static func make(path: String, m: Vector4, pad: Vector4) -> Slice2x:
	var s := Slice2x.new()
	s.texture = load(path)
	s.margin_1x = m
	s.content_margin_left = pad.x; s.content_margin_top = pad.y
	s.content_margin_right = pad.z; s.content_margin_bottom = pad.w
	return s

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null: return
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, Vector2(0.5, 0.5), 0.0, rect.position))
	RenderingServer.canvas_item_add_nine_patch(to_canvas_item, Rect2(Vector2.ZERO, rect.size * 2.0), Rect2(), texture.get_rid(),
		Vector2(margin_1x.x, margin_1x.y) * 2.0, Vector2(margin_1x.z, margin_1x.w) * 2.0,
		RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH, true, modulate)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D.IDENTITY)
