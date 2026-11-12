## Recipe card (Art P2): recipe_N@2x (or recipe_locked@2x) with the name in a Godot Label on the empty ribbon
## (ribbon rect (32,232)-(206,280) of the 240x320 1x card, DM Serif Display, ink, centred; no baked-in text).
## SPEC v1.3: no "Chapter N" line on the card; an unlocked card is "alive": the medallion illustration breathes and
## a shine sweeps the card (ui/shaders/recipe_card.gdshader), steam rises from the cakes, gold sparkles twinkle
## around the medallion and a warm glow sits behind the card (drawn here, no new art). celebrate() (chapter end)
## adds a slow float/tilt and a sparkle burst. Flip-in: scale X 0->1 on the back, then the card (~400 ms, SPEC §8).
extends Control

const Chapters = preload("res://game/chapters.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const Pal = preload("res://ui/theme/art_palette.gd")

var chapter := 1
var unlocked := false
var compact := false       # spread thumbnails (All recipes baked): art only; names live in the Recipe Book
var tex: TextureRect
var name_label: Label
const CardShader = preload("res://ui/shaders/recipe_card.gdshader")
const STEAM := preload("res://assets/board/steam_puff@2x.png")
## Sparkles around the medallion (1x card px, phase offset, size): fixed so every card twinkles the same calm way.
const SPARKS := [[46, 52, 0.0, 9.0], [196, 60, 1.3, 7.0], [214, 140, 2.6, 8.0], [28, 168, 0.7, 7.0], [178, 206, 2.0, 9.0],
	[66, 214, 3.1, 6.0], [120, 30, 1.8, 6.0]]
var fx: Control                  # sparkles + steam, drawn over the art
var mat: ShaderMaterial
var celebrating := false         # chapter end: float/tilt + sparkle burst
var burst_t0 := -1.0

func setup(ch: int, owned: bool) -> void:
	chapter = ch; unlocked = owned
	custom_minimum_size = Vector2(168, 224)
	tex = TextureRect.new(); tex.name = "Art"; tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	mat = ShaderMaterial.new(); mat.shader = CardShader; tex.material = mat
	add_child(tex)
	fx = Control.new(); fx.name = "Fx"; fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT); fx.draw.connect(_draw_fx)
	add_child(fx)
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
	name_label.text = Chapters.RECIPES[chapter - 1] if unlocked else ""
	name_label.visible = unlocked and not compact
	mat.set_shader_parameter("magic", 1.0 if unlocked else 0.0)
	mat.set_shader_parameter("shine", 0.25 if compact else 0.38)
	set_process(unlocked)
	queue_redraw(); fx.queue_redraw()
	_place()

const RIBBON := Rect2(32, 232, 174, 48)   # empty ribbon on the 240x320 1x card art
const RIBBON_PAD := 6.0                   # 1x px of padding inside each ribbon end
const MIN_FS := 14                        # SPEC §3.5/TT-AC-07: labels >= 14 px
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
	pivot_offset = size / 2.0

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

# ------------------------------------------------------------------ magic (SPEC v1.3)
func now_s() -> float:   # frame clock in Movie Maker mode (preview videos), wall clock otherwise (see board_view.now_ms)
	return Engine.get_process_frames() / 60.0 if OS.has_feature("movie") else Time.get_ticks_msec() / 1000.0

func _process(_dt: float) -> void:
	if not is_visible_in_tree(): return                 # hidden screens cost nothing
	var t := now_s()
	mat.set_shader_parameter("time_s", t)
	if celebrating:                                   # slow float: tilt +-1.2 deg, breathe 1.0..1.02
		rotation = deg_to_rad(1.2 * sin(t * 1.1))
		scale.y = 1.0 + 0.01 * (1.0 + sin(t * 1.7)); if scale.x > 0.99: scale.x = scale.y
	queue_redraw(); fx.queue_redraw()

## Chapter end: the card floats and a ring of sparkles bursts out once (call after flip_in()).
func celebrate() -> void:
	celebrating = true; burst_t0 = now_s() + 0.45     # burst as the flip lands
	set_process(true)

func stop_celebrate() -> void:
	celebrating = false; rotation = 0.0; scale = Vector2.ONE; burst_t0 = -1.0

func _card_xf() -> Array:   # [scale k, origin] of the 240x320 art in this control
	var k := minf(size.x / 240.0, size.y / 320.0)
	return [k, (size - Vector2(240, 320) * k) / 2.0]

## Warm golden glow behind the card, pulsing gently (unlocked only).
func _draw() -> void:
	if not unlocked or size.x <= 0.0: return
	var xf := _card_xf(); var k: float = xf[0]; var o: Vector2 = xf[1]
	var pulse := 0.5 + 0.5 * sin(now_s() * 1.6)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(Pal.HINT_GOLD, 0.0)
	sb.set_corner_radius_all(int(18 * k))
	sb.shadow_color = Color(Pal.HINT_GOLD, (0.30 if compact else 0.45) + 0.20 * pulse)
	sb.shadow_size = int((6.0 if compact else 14.0) * k + 6.0 * pulse * k)
	draw_style_box(sb, Rect2(o + Vector2(10, 10) * k, Vector2(220, 300) * k))

static func _sparkle(ci: CanvasItem, c: Vector2, r: float, a: float) -> void:
	if a <= 0.01 or r <= 0.5: return
	var pts := PackedVector2Array()
	for i in 8:
		var ang := i * PI / 4.0
		pts.append(c + Vector2.from_angle(ang) * (r if i % 2 == 0 else r * 0.28))
	ci.draw_colored_polygon(pts, Color(Pal.HINT_GOLD, a))
	ci.draw_circle(c, r * 0.22, Color(1, 1, 0.95, a))

func _draw_fx() -> void:
	if not unlocked or size.x <= 0.0: return
	var xf := _card_xf(); var k: float = xf[0]; var o: Vector2 = xf[1]
	var t := now_s()
	# steam: two soft puffs rising from the cakes, staggered (not on spread thumbnails)
	if not compact:
		for j in 2:
			var p := fmod(t / 2.6 + j * 0.5, 1.0)
			var base := o + Vector2(104 + 30 * j, 128) * k
			var side := (34.0 + 18.0 * p) * k
			var a := sin(p * PI) * 0.55
			fx.draw_texture_rect(STEAM, Rect2(base + Vector2(-side / 2.0 + 6.0 * sin(t * 2.0 + j) * k, -side - 46.0 * p * k), Vector2(side, side)),
				false, Color(1, 1, 1, a))
	# twinkling sparkles around the medallion
	for s in SPARKS:
		var tw := 0.5 + 0.5 * sin(t * 2.3 + s[2] * 2.0)
		_sparkle(fx, o + Vector2(s[0], s[1]) * k, s[3] * k * (0.6 + 0.6 * tw) * (0.7 if compact else 1.0), 0.25 + 0.75 * tw * tw)
	# chapter-end burst: 12 sparkles fly out from the medallion and fade (0.9 s)
	if burst_t0 > 0.0:
		var bp := (t - burst_t0) / 0.9
		if bp >= 0.0 and bp <= 1.0:
			var c := o + Vector2(119, 126) * k
			for i in 12:
				var dir := Vector2.from_angle(i * TAU / 12.0 + 0.2)
				_sparkle(fx, c + dir * (60.0 + 90.0 * bp) * k, (10.0 - 4.0 * bp) * k, 1.0 - bp)

## Flip in: back (locked) scales X 0->1->0, then the unlocked card 0->1 (~400 ms total).
func flip_in() -> void:
	unlocked = false; refresh(); pivot_offset = size / 2.0; scale.x = 0.0
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 1.0, 0.1); tw.tween_property(self, "scale:x", 0.0, 0.1)
	tw.tween_callback(func(): unlocked = true; refresh())
	tw.tween_property(self, "scale:x", 1.0, 0.2)
