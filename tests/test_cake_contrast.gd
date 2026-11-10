## SPEC v1.2 §10 / TT-AC-33 (cake part): every shipped cake sprite (one per chapter + the daily cake) keeps the B2
## readability rules on all 9 dough patches, measured on the @2x source pixels along 360 rays from the sprite centre:
##  (a) cream halo silhouette: on >= 98% of rays a cream pixel (#FFF8EC +-40) lies 2-6 px inside the outermost opaque
##      pixel (the light rim that separates the cake from any patch);
##  (b) ink outline: on >= 94% of rays an ink pixel (#43283A +-60) lies within 32 px inside the outer edge (measured
##      2026-11-03: berry 0.99, scone/bakewell 1.00, lemon/apricot/chocolate 0.99, custard 0.99, victoria 0.95 and
##      macaron 0.95; the misses are the un-outlined strawberry on the victoria slice and the macaron feet, Art
##      follow-up in SPEC v1.2 post-lock notes);
##  (c) ink vs every patch fill >= 3:1 (WCAG contrast).
extends GutTest
const Chapters = preload("res://game/chapters.gd")
const Pal = preload("res://ui/theme/art_palette.gd")

const INK := Color("43283A")
const CREAM := Color("FFF8EC")

func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)

func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a); var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() * 255.0

func _image(name: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path("res://assets/board/cake_%s@2x.png" % name))

## [ink coverage, halo coverage] over 360 rays.
func _ring_coverage(img: Image) -> Array:
	var w := img.get_width(); var h := img.get_height()
	var ctr := Vector2(img.get_used_rect().get_center())
	var ink_hits := 0; var halo_hits := 0
	for k in 360:
		var d := Vector2.from_angle(deg_to_rad(k))
		var edge := -1.0
		var t := 0.0
		while true:
			var p := ctr + d * t
			if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h: break
			if img.get_pixelv(Vector2i(p)).a > 0.5: edge = t
			t += 0.5
		if edge < 0: continue
		for s in [2.0, 3.0, 4.0, 5.0, 6.0]:
			var c := img.get_pixelv(Vector2i(ctr + d * (edge - s)))
			if c.a > 0.8 and _dist(c, CREAM) < 40.0: halo_hits += 1; break
		var s := 0.0
		while s <= 32.0 and edge - s >= 0.0:
			var c := img.get_pixelv(Vector2i(ctr + d * (edge - s)))
			if c.a > 0.8 and _dist(c, INK) < 60.0: ink_hits += 1; break
			s += 0.5
	return [ink_hits / 360.0, halo_hits / 360.0]

func test_every_shipped_cake_is_readable_on_every_patch():
	var names: Array = Chapters.CAKES.duplicate(); names.append(Chapters.DAILY_CAKE)
	for nm in names:
		var img := _image(nm)
		assert_not_null(img, nm)
		if img == null: continue
		assert_eq(img.get_size(), Vector2i(256, 256), "%s @2x is 256 px" % nm)
		var cov := _ring_coverage(img)
		assert_gte(cov[0], 0.94, "%s ink outline coverage %.3f" % [nm, cov[0]])
		assert_gte(cov[1], 0.98, "%s cream halo coverage %.3f" % [nm, cov[1]])
	for i in Pal.REGION_COLORS.size():
		assert_gte(_contrast(INK, Pal.REGION_COLORS[i]), 3.0, "ink on %s" % Pal.REGION_NAMES[i])
