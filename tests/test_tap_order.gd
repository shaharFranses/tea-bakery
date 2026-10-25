## SPEC v1.0 D-12 / TT-AC-06 / TT-AC-22: mold-first tap cycle (default) and "cake first" setting, right-click mold toggle,
## auto-molds derived (never stored), settings persisted in the save dict.
extends GutTest
const Cells = preload("res://game/cells.gd")
const Settings = preload("res://game/settings.gd")
const Gen = preload("res://game/generator.gd")

func _cycle(order: String) -> Array:
	var s := Cells.EMPTY; var seen := []
	for k in 3:
		s = Cells.next_state(s, order); seen.append(Cells.NAMES[s])
	return seen

func test_default_order_mold_first():
	assert_eq(Settings.new().tap_order, Cells.ORDER_MOLD_FIRST)
	assert_eq(_cycle(Cells.ORDER_MOLD_FIRST), ["mold", "cake", "empty"])

func test_cake_first_order():
	assert_eq(_cycle(Cells.ORDER_CAKE_FIRST), ["cake", "mold", "empty"])

func test_auto_mold_cell_cycles_like_empty_and_cake_on_mold_allowed():
	assert_eq(Cells.next_state(Cells.MOLD_AUTO, Cells.ORDER_MOLD_FIRST), Cells.MOLD)
	assert_eq(Cells.next_state(Cells.MOLD_AUTO, Cells.ORDER_CAKE_FIRST), Cells.CAKE, "auto-mold never blocks a cake")
	assert_eq(Cells.next_state(Cells.MOLD, Cells.ORDER_MOLD_FIRST), Cells.CAKE, "cake on a mold cell")

func test_right_click_toggles_mold_never_cake():
	assert_eq(Cells.right_click(Cells.EMPTY), Cells.MOLD)
	assert_eq(Cells.right_click(Cells.MOLD), Cells.EMPTY)
	assert_eq(Cells.right_click(Cells.MOLD_AUTO), Cells.MOLD)
	assert_eq(Cells.right_click(Cells.CAKE), Cells.CAKE)

func test_auto_molds_derived_and_removed_with_their_cake():
	var t := Gen.tutorial(); var n: int = t.n
	var cells := PackedInt32Array(); cells.resize(n * n); cells.fill(Cells.EMPTY)
	cells[0] = Cells.CAKE                      # A1
	cells[2] = Cells.MOLD                      # player mold in row 1 stays a player mold
	var a := Cells.auto_molds(n, t.regions, cells)
	assert_true(a.has(1) and a.has(n) and a.has(n + 1), "row, column, diagonal neighbour")
	assert_false(a.has(2), "player mold not downgraded")
	assert_eq(Cells.shown(2, cells, a), Cells.MOLD)
	assert_eq(Cells.auto_molds(n, t.regions, cells, false), {}, "setting OFF hides them")
	cells[0] = Cells.EMPTY
	assert_eq(Cells.auto_molds(n, t.regions, cells), {}, "removing the cake removes its auto-molds")
	assert_eq(cells[2], Cells.MOLD)

func test_settings_persist_both_orders():
	for order in [Cells.ORDER_CAKE_FIRST, Cells.ORDER_MOLD_FIRST]:
		var s = Settings.new(); s.tap_order = order; s.auto_mold = false
		var saved := JSON.parse_string(JSON.stringify({"settings": s.to_dict()}))   # through the save format
		var r = Settings.new(); r.from_dict(saved.settings)
		assert_eq(r.tap_order, order); assert_false(r.auto_mold)
		assert_eq(Cells.NAMES[Cells.next_state(Cells.EMPTY, r.tap_order)], "cake" if order == Cells.ORDER_CAKE_FIRST else "mold")
	var bad = Settings.new(); bad.from_dict({"tap_order": "x"})
	assert_eq(bad.tap_order, Cells.ORDER_MOLD_FIRST, "unknown value -> default")
	assert_true(bad.auto_mold, "auto-molds ON by default (D-13)")

func test_analytics_noop_sink():
	assert_eq(Analytics.sink, "noop")
	Analytics.board_start("c1-b1", "chapter", 5, 1, false)   # must not error; no network API exists in the module
	var src := FileAccess.get_file_as_string("res://autoload/analytics.gd")
	for bad in ["HTTPRequest", "HTTPClient", "sendBeacon", "fetch(", "XMLHttpRequest", "JavaScriptBridge", "FileAccess", "Store."]:
		assert_false(bad in src, "analytics module has no %s" % bad)
