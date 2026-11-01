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
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF; name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.clip_text = false
	add_child(name_label)
	resized.connect(_place)
	refresh()

func refresh() -> void:
	tex.texture = load("res://assets/recipes/%s@2x.png" % ("recipe_%d" % chapter if unlocked else "recipe_locked"))
	ch_label.text = "Chapter %d" % chapter
	name_label.text = Chapters.RECIPES[chapter - 1] if unlocked else ""
	name_label.visible = unlocked; ch_label.visible = unlocked
	_place()

const RIBBON := Rect2(32, 232, 174, 48)   # empty ribbon on the 240x320 1x card art
const RIBBON_PAD := 6.0                   # 1x px of padding inside each ribbon end
const MIN_FS := 12                        # never below the 12 px text minimum
var fit := {}                             # {fs, text_w, ribbon_w, fits} (QA dump / tests)

## Ribbon auto-fit: one line, the largest size in [MIN_FS, 20 px * card scale] whose text width fits inside the ribbon.
func _place() -> void:
	# card drawn KEEP_ASPECT_CENTERED in this rect: 240x320 aspect
	var k := minf(size.x / 240.0, size.y / 320.0)
	var o := (size - Vector2(240, 320) * k) / 2.0
	var avail := (RIBBON.size.x - 2.0 * RIBBON_PAD) * k
	var avail_h := RIBBON.size.y * k
	var font: Font = TtTheme.serif()
	var txt: String = Chapters.RECIPES[chapter - 1] if unlocked else ""
	var top := maxi(MIN_FS, int(20.0 * k))
	var best := {}
	for lines in [1, 2]:                       # prefer one line; two lines only if one line can't fit at 12 px
		for fs in range(top, MIN_FS - 1, -1):
			var parts: Array = [txt] if lines == 1 else _split2(txt, font, fs)
			var w := 0.0
			for part in parts: w = maxf(w, font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			var lead := -floorf(fs / 4.0) if parts.size() == 2 else 0.0   # tight leading for the 2-line ribbon
			var h := _line_h(font, fs) * parts.size() + lead
			if w <= avail and h <= avail_h + 0.5:
				best = {"fs": fs, "lines": parts.size(), "text_w": w, "text_h": h, "parts": parts, "lead": int(lead)}; break
		if not best.is_empty(): break
	if best.is_empty():
		var w1 := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FS).x
		best = {"fs": MIN_FS, "lines": 1, "text_w": w1, "text_h": _line_h(font, MIN_FS), "parts": [txt], "lead": 0}
	fit = {"fs": best.fs, "lines": best.lines, "text_w": best.text_w, "text_h": best.text_h, "ribbon_w": avail, "ribbon_h": avail_h,
		"fits": best.text_w <= avail + 0.5 and best.text_h <= avail_h + 0.5, "text": txt}
	name_label.text = "\n".join(best.parts)
	name_label.add_theme_constant_override("line_spacing", best.lead)
	name_label.add_theme_font_size_override("font_size", best.fs)
	name_label.position = o + RIBBON.position * k; name_label.size = RIBBON.size * k
	ch_label.position = o + Vector2(32, 206) * k; ch_label.size = Vector2(174, 22) * k

## Line height scaled from one reference measurement: FontFile.get_height(12) was observed returning 36 (2x) after the
## same font had been queried at other sizes in one run (Godot 4.3 size-cache quirk), so never trust the per-size value.
static var _ref_h := -1.0
static func _line_h(font: Font, fs: int) -> float:
	if _ref_h < 0.0: _ref_h = font.get_height(100) / 100.0
	return ceilf(_ref_h * fs)

## Two balanced lines at a word break (the split with the narrower longer line).
static func _split2(t: String, font: Font, fs: int) -> Array:
	var words := t.split(" ")
	if words.size() < 2: return [t]
	var best: Array = [t]; var bw := INF
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i)); var b := " ".join(words.slice(i))
		var w := maxf(font.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, font.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if w < bw: bw = w; best = [a, b]
	return best

## Flip in: back (locked) scales X 0->1->0, then the unlocked card 0->1 (~400 ms total).
func flip_in() -> void:
	unlocked = false; refresh(); pivot_offset = size / 2.0; scale.x = 0.0
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 1.0, 0.1); tw.tween_property(self, "scale:x", 0.0, 0.1)
	tw.tween_callback(func(): unlocked = true; refresh())
	tw.tween_property(self, "scale:x", 1.0, 0.2)
