## Step 3: recipe cards 1-8 and shelf décor per assets/decor/shelf_slots.json (ch3 gingham drape, ch6 bunting garland).
extends GutTest
const Chapters = preload("res://game/chapters.gd")
const Shelf = preload("res://scenes/shelf.gd")

func test_recipe_art_all_chapters():
	for ch in range(1, 9):
		assert_not_null(load("res://assets/recipes/recipe_%d@2x.png" % ch), "recipe_%d" % ch)

func test_shelf_slots_and_overlays():
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/decor/shelf_slots.json"))
	for ch in [1, 2, 4, 5, 7, 8]: assert_true(d.slots.has(str(ch)), "slot for ch%d" % ch)
	assert_eq(d.slots["3"].get("overlay"), "shelf_gingham_drape"); assert_eq(d.slots["6"].get("overlay"), "shelf_bunting_garland")
	var sh = Shelf.new(); sh.size = Vector2(360, 160); add_child_autofree(sh)
	assert_not_null(sh._tex.shelf_gingham_drape); assert_not_null(sh._tex.shelf_bunting_garland)
	for ch in range(1, 9): assert_not_null(sh._tex[ch], "decor %d" % ch)
	sh.set_owned([1, 2, 3, 4, 5, 6, 7, 8]); await wait_frames(2)
	assert_eq(sh.owned.size(), 8)
