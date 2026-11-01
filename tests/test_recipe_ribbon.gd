## Recipe-name ribbon auto-fit (step 3; SPEC v1.0.2 card 5 "Cherry Bakewell"): every card name (1-8) fits inside the
## ribbon (width minus padding, height) at >= 12 px, on the Recipe Book and chapter-end card sizes of all 3 CI layouts.
extends GutTest
const RecipeCard = preload("res://scenes/recipe_card.gd")
const Chapters = preload("res://game/chapters.gd")
const Main = preload("res://scenes/main.gd")
const LAYOUTS := [[Vector2(390, 844), "portrait"], [Vector2(800, 450), "wide"], [Vector2(1280, 720), "wide"]]

func _card(ch: int, h: float) -> Control:
	var c = RecipeCard.new(); add_child_autofree(c); c.setup(ch, true)
	c.custom_minimum_size = Vector2(h * 0.75, h); c.size = Vector2(h * 0.75, h); c._place()
	return c

func test_every_name_fits_all_layouts():
	for lay in LAYOUTS:
		var hs: Dictionary = Main.page_card_heights(lay[0], lay[1])
		for where in ["book", "end"]:
			for ch in range(1, 9):
				var c = _card(ch, hs[where])
				assert_true(c.fit.fits, "%s %s card %d '%s' fs=%d lines=%d w=%.1f/%.1f h=%.1f/%.1f" % [lay[0], where, ch, c.fit.text,
					c.fit.fs, c.fit.lines, c.fit.text_w, c.fit.ribbon_w, c.fit.text_h, c.fit.ribbon_h])
				assert_gte(c.fit.fs, 14)

func test_cherry_bakewell_explicit():
	assert_eq(Chapters.RECIPES[4], "Cherry Bakewell")
	for lay in LAYOUTS:
		var hs: Dictionary = Main.page_card_heights(lay[0], lay[1])
		for where in ["book", "end"]:
			var c = _card(5, hs[where])
			assert_eq(c.fit.text, "Cherry Bakewell")
			assert_true(c.fit.fits and c.fit.fs >= 14, "Cherry Bakewell fits the %s ribbon at %s (fs %d, lines %d)" % [where, lay[0], c.fit.fs, c.fit.lines])
