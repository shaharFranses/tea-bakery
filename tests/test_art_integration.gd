## Art kit integration (art/HANDOFF_GODOT.md P0-P2): palette, sprite sizes, @2x-only loads, import settings.
extends GutTest

const BoardView = preload("res://scenes/board_view.gd")
const Pal = preload("res://ui/theme/art_palette.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const UiLayout = preload("res://game/ui_layout.gd")

func test_mold_and_cake_draw_sizes() -> void:
	assert_almost_eq(BoardView.mold_side(100.0), 70.0, 0.001, "mold drawn at 0.70 x cell")
	assert_almost_eq(BoardView.cake_side(100.0), 100.0, 0.001, "cake drawn at 1.0 x cell")

func test_only_berry_cake_and_2x_sprites() -> void:
	assert_eq(BoardView.CAKE_SPRITE, "res://assets/board/cake_berry@2x.png")
	assert_eq(BoardView.MOLD_SPRITE, "res://assets/board/mold@2x.png")
	var src := FileAccess.get_file_as_string("res://scenes/board_view.gd")
	for c in ["lemon", "victoria", "scone", "bakewell", "chocolate", "macaron", "custard", "apricot"]:
		assert_false(src.contains("cake_" + c), "extra cake %s not wired in v1" % c)
	var bv = BoardView.new(); add_child_autofree(bv)
	for k in bv.tex: assert_not_null(bv.tex[k], k)
	assert_eq(bv.tiles.size(), 9)
	for i in 9: assert_true(bv.tiles[i].resource_path.ends_with("tile_%d_%s@2x.png" % [i, Pal.REGION_NAMES[i]]))

func test_tile_rect_geometry() -> void:
	var t := BoardView.tile_rect(Vector2.ZERO, 100.0, 0, 0)
	assert_almost_eq(t.position.x, 3.75, 0.001); assert_almost_eq(t.size.x, 92.5, 0.001)

func test_conflict_units() -> void:
	var reg := PackedInt32Array(); reg.resize(25); reg.fill(0)
	for i in 25: reg[i] = i % 5
	var u := BoardView.units_of_conflicts(5, reg, [Vector2i(0, 0), Vector2i(0, 3)])   # same row 0
	for c in 5: assert_true(u.has(c), "row 0 cell %d tinted" % c)

func test_theme_builds_with_fonts() -> void:
	var th := TtTheme.build()
	assert_not_null(th.default_font)
	assert_eq(th.default_font_size, 16)
	assert_true(th.get_font("font", "TitleLabel").resource_path.ends_with("DMSerifDisplay-Regular.ttf"))
	assert_true(th.has_stylebox("panel", "CoachBubble"))
	assert_eq(TtTheme.BUBBLE_3LINE_H, 88.0)

func test_layout_floors() -> void:
	assert_true(UiLayout.BOARD_MIN >= 352.0)
	assert_eq(UiLayout.portrait_gap(844.0), 8)
	assert_eq(UiLayout.portrait_gap(640.0), 4)

func test_import_settings() -> void:
	var nine := ["tray_frame", "btn_", "panel_", "chip_honey", "coach_bubble"]
	var n := 0
	for dir in ["res://assets/board/", "res://assets/ui/", "res://assets/ui/icons/", "res://assets/decor/", "res://assets/recipes/"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".png.import"): continue
			var cf := ConfigFile.new(); assert_eq(cf.load(dir + f), OK)
			var is9 := nine.any(func(p): return f.begins_with(p))
			assert_eq(cf.get_value("params", "compress/mode"), 0, f + " lossless")
			assert_eq(cf.get_value("params", "mipmaps/generate"), not is9, f + " mipmaps")
			n += 1
	assert_true(n > 150, "imports checked: %d" % n)
