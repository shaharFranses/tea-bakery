## SPEC v1.3 §8: recipe cards carry no "Chapter N" line; unlocked cards are "alive" (shader magic on, sparkles,
## steam, glow), locked backs are plain; chapter end celebrates (float + burst) and the shader never darkens the art.
extends GutTest
const RecipeCard = preload("res://scenes/recipe_card.gd")

func _card(ch: int, owned: bool) -> Control:
	var c = RecipeCard.new(); add_child_autofree(c); c.setup(ch, owned); c.size = Vector2(240, 320)
	return c

func test_no_chapter_label():
	var c = _card(1, true)
	for n in c.find_children("*", "Label", true, false):
		assert_false(n.text.begins_with("Chapter"), "no chapter line on the card: %s" % n.text)
	assert_eq(c.name_label.text, "Scones & clotted cream")

func test_magic_on_unlocked_only():
	var c = _card(2, true)
	assert_eq(c.mat.get_shader_parameter("magic"), 1.0)
	assert_true(c.is_processing())
	c.unlocked = false; c.refresh()
	assert_eq(c.mat.get_shader_parameter("magic"), 0.0)
	assert_false(c.is_processing())

func test_celebrate_and_stop():
	var c = _card(3, true)
	c.celebrate(); assert_true(c.celebrating); assert_gt(c.burst_t0, 0.0)
	c.stop_celebrate(); assert_false(c.celebrating); assert_eq(c.rotation, 0.0); assert_eq(c.scale, Vector2.ONE)

func test_shader_samples_the_art_once():
	var src := FileAccess.get_file_as_string("res://ui/shaders/recipe_card.gdshader")
	assert_true(src.contains("COLOR = col * vcol;"), "multiply by the vertex colour, not COLOR (which already holds the texture)")
	assert_false(src.contains("col * COLOR"))
