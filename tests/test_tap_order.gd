## SPEC v1.0 D-12 / TT-AC-06: mold-first tap cycle (default) and "cake first" setting, right-click mold toggle,
## no auto-molds (placing a cake never marks other cells), settings persisted in the save dict.
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

func test_cake_on_mold_allowed():
	assert_eq(Cells.next_state(Cells.MOLD, Cells.ORDER_MOLD_FIRST), Cells.CAKE, "cake on a mold cell")

func test_right_click_toggles_mold_never_cake():
	assert_eq(Cells.right_click(Cells.EMPTY), Cells.MOLD)
	assert_eq(Cells.right_click(Cells.MOLD), Cells.EMPTY)
	assert_eq(Cells.right_click(Cells.CAKE), Cells.CAKE)

func test_no_auto_molds():
	var src := FileAccess.get_file_as_string("res://game/cells.gd")
	assert_false(src.contains("MOLD_AUTO") or src.contains("auto_molds"), "no derived auto-mold state")
	assert_false("auto_mold" in Settings.new().to_dict(), "no Auto-molds setting")

func test_settings_persist_both_orders():
	for order in [Cells.ORDER_CAKE_FIRST, Cells.ORDER_MOLD_FIRST]:
		var s = Settings.new(); s.tap_order = order
		var saved: Dictionary = JSON.parse_string(JSON.stringify({"settings": s.to_dict()}))   # through the save format
		var r = Settings.new(); r.from_dict(saved.settings)
		assert_eq(r.tap_order, order)
		assert_eq(Cells.NAMES[Cells.next_state(Cells.EMPTY, r.tap_order)], "cake" if order == Cells.ORDER_CAKE_FIRST else "mold")
	var bad = Settings.new(); bad.from_dict({"tap_order": "x"})
	assert_eq(bad.tap_order, Cells.ORDER_MOLD_FIRST, "unknown value -> default")

func test_analytics_noop_sink():
	assert_eq(Analytics.sink, "noop")
	Analytics.board_start("c1-b1", "chapter", 5, 1, false)   # must not error; no network API exists in the module
	var src := FileAccess.get_file_as_string("res://autoload/analytics.gd")
	for bad in ["HTTPRequest", "HTTPClient", "sendBeacon", "fetch(", "XMLHttpRequest", "JavaScriptBridge", "FileAccess", "Store."]:
		assert_false(bad in src, "analytics module has no %s" % bad)
