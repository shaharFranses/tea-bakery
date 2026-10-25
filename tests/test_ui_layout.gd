## Responsive layout rules (game/ui_layout.gd): units never smaller than CSS px, breakpoints, wide split.
extends GutTest
const L = preload("res://game/ui_layout.gd")

func test_modes_and_breakpoint():
	assert_eq(L.mode(Vector2(390, 844)), "portrait")
	assert_eq(L.mode(Vector2(800, 450)), "wide")
	assert_eq(L.mode(Vector2(1280, 720)), "wide")
	assert_eq(L.mode(Vector2(600, 600)), "portrait", "square stays portrait (aspect > 1.0 is wide)")
	assert_eq(L.mode(Vector2(601, 600)), "wide")

func test_units_never_smaller_than_css_px():
	for css in [Vector2(320, 568), Vector2(390, 844), Vector2(768, 1024), Vector2(800, 450), Vector2(1280, 720),
			Vector2(1920, 1080), Vector2(740, 360), Vector2(2560, 1440)]:
		assert_true(L.css_per_unit(css) >= 0.999, "css_per_unit >= 1 at %s" % css)
		assert_true(L.logical_size(css).x <= css.x and L.logical_size(css).y <= css.y)
	assert_eq(L.logical_size(Vector2(390, 844)), Vector2(390, 844), "phone 1:1")
	assert_eq(L.logical_size(Vector2(800, 450)), Vector2(800, 450), "CrazyGames embed 1:1")
	assert_eq(L.logical_size(Vector2(1920, 1080)), Vector2(1280, 720), "big desktop scales up")

func test_wide_split_800x450_fits_9x9_at_44():
	var sp = L.wide_split(Vector2(800, 450))
	assert_true(sp.board.size.x / 9.0 >= 44.0, "9x9 cells %.1f >= 44" % (sp.board.size.x / 9.0))
	assert_true(sp.panel.size.x >= L.PANEL_MIN_W)
	assert_true(sp.panel.end.x <= 800.0 and sp.board.end.y <= 450.0)
	assert_false(sp.board.intersects(sp.panel))
