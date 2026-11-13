## Art kit integration (art/HANDOFF_GODOT.md P0-P2): palette, sprite sizes, @2x-only loads, import settings.
extends GutTest

const BoardView = preload("res://scenes/board_view.gd")
const Pal = preload("res://ui/theme/art_palette.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const UiLayout = preload("res://game/ui_layout.gd")

func test_mold_and_cake_draw_sizes() -> void:
	assert_almost_eq(BoardView.mold_side(100.0), 70.0, 0.001, "mold drawn at 0.70 x cell")
	assert_almost_eq(BoardView.cake_side(100.0), 100.0, 0.001, "cake drawn at 1.0 x cell")
	assert_eq(BoardView.AUTO_ALPHA, 0.5, "auto-mold = same sprite at 0.5 alpha")
	assert_true(BoardView.AUTO_ALPHA <= 0.6, "TT-AC-22")

## SPEC v1.2 (D-03 revised): one cake per chapter (its recipe), chocolate on the daily, berry v2 on debug boards.
func test_cake_pieces_and_2x_sprites() -> void:
	const Chapters = preload("res://game/chapters.gd")
	assert_eq(Chapters.CAKES, ["scone", "victoria", "lemon", "apricot", "bakewell", "berry", "chocolate", "macaron"])
	assert_eq(Chapters.DAILY_CAKE, "custard"); assert_eq(Chapters.DEFAULT_CAKE, "berry")
	assert_eq(Chapters.cake_for(1), "scone"); assert_eq(Chapters.cake_for(8), "macaron"); assert_eq(Chapters.cake_for(0), "berry")
	for c in Chapters.CAKES + [Chapters.DAILY_CAKE]: assert_true(c in BoardView.CAKE_PIECES, c)
	assert_eq(BoardView.MOLD_SPRITE, "res://assets/board/mold@2x.png")
	var bv = BoardView.new(); add_child_autofree(bv)
	for c in BoardView.CAKE_PIECES: assert_true(bv.tex["cake_" + c].resource_path.ends_with("cake_%s_top@2x.png" % c))
	bv.setup(5, PackedInt32Array(), [], "lemon"); assert_eq(bv.piece, "lemon")
	bv.setup(5, PackedInt32Array(), [], "nope"); assert_eq(bv.piece, "berry", "unknown piece falls back to berry")
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
