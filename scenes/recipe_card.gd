## Recipe card (Art P2): recipe_N@2x (or recipe_locked@2x) with the name in a Godot Label on the empty ribbon
## (ribbon rect (32,232)-(206,280) of the 240x320 1x card, DM Serif Display, ink, centred; no baked-in text) and a
## Lexend chapter label above the ribbon. Flip-in: scale X 0->1 on the back, then the card (~400 ms, SPEC §8).
extends Control

const Chapters = preload("res://game/chapters.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const Pal = preload("res://ui/theme/art_palette.gd")

var chapter := 1
var unlocked := false
var tex: TextureRect
var name_label: Label
var ch_label: Label

func setup(ch: int, owned: bool) -> void:
	chapter = ch; unlocked = owned
	custom_minimum_size = Vector2(168, 224)
	tex = TextureRect.new(); tex.name = "Art"; tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tex)
	ch_label = Label.new(); ch_label.name = "Chapter%d" % ch; ch_label.add_theme_font_size_override("font_size", 14)
	ch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ch_label)
	name_label = Label.new(); name_label.name = "Recipe%d" % ch
	name_label.add_theme_font_override("font", TtTheme.serif()); name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Pal.EARL_GREY_INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	resized.connect(_place)
	refresh()

func refresh() -> void:
	tex.texture = load("res://assets/recipes/%s@2x.png" % ("recipe_%d" % chapter if unlocked else "recipe_locked"))
	ch_label.text = "Chapter %d" % chapter
	name_label.text = Chapters.RECIPES[chapter - 1] if unlocked else ""
	name_label.visible = unlocked; ch_label.visible = unlocked
	_place()

func _place() -> void:
	# card drawn KEEP_ASPECT_CENTERED in this rect: 240x320 aspect
	var k := minf(size.x / 240.0, size.y / 320.0)
	var o := (size - Vector2(240, 320) * k) / 2.0
	var fs := clampi(int(20.0 * k), 14, 20)   # DM Serif 20 px at 1x; never below the 14 px label floor (TT-AC-07)
	name_label.add_theme_font_size_override("font_size", fs)
	name_label.position = o + Vector2(26, 228) * k; name_label.size = Vector2(186, 56) * k
	ch_label.position = o + Vector2(32, 206) * k; ch_label.size = Vector2(174, 22) * k

## Flip in: back (locked) scales X 0->1->0, then the unlocked card 0->1 (~400 ms total).
func flip_in() -> void:
	unlocked = false; refresh(); pivot_offset = size / 2.0; scale.x = 0.0
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 1.0, 0.1); tw.tween_property(self, "scale:x", 0.0, 0.1)
	tw.tween_callback(func(): unlocked = true; refresh())
	tw.tween_property(self, "scale:x", 1.0, 0.2)
