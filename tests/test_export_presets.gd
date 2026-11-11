## Export filter vs shipped sprites: every sprite the game loads at runtime must be in the pck. Regression guard for
## SPEC v1.2: the per-chapter cakes were excluded by an older "berry only" rule and failed to load in the web build
## ("No loader found for resource: res://assets/board/cake_scone@2x.png") while editor/tests still passed.
extends GutTest
const BoardView = preload("res://scenes/board_view.gd")
const Chapters = preload("res://game/chapters.gd")

func _excludes() -> Array:
	var cf := ConfigFile.new()
	assert_eq(cf.load("res://export_presets.cfg"), OK)
	var out := []
	for sec in cf.get_sections():
		if sec.ends_with(".options"): continue
		out.append(str(cf.get_value(sec, "exclude_filter", "")))
	return out

func test_every_cake_piece_ships():
	var pieces: Array = BoardView.CAKE_PIECES.duplicate()
	for c in Chapters.CAKES + [Chapters.DAILY_CAKE, Chapters.DEFAULT_CAKE]: assert_true(c in pieces, c)
	var ex := _excludes()
	assert_eq(ex.size(), 2, "Web + Web Release presets")
	for f in ex:
		for c in pieces:
			assert_false(("assets/board/cake_%s@2x.png" % c) in f, "cake_%s@2x.png must not be excluded from the export" % c)

func test_card_fx_assets_ship():
	for f in _excludes():
		assert_false("steam_puff@2x" in f, "recipe-card steam needs steam_puff@2x")
		assert_false("ui/shaders" in f, "recipe-card shader must ship")
