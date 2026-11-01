## Starter mechanics tests (GUT). Run: godot --headless -s addons/gut/gut_cmdln.gd -gexit
extends GutTest

const MuteState = preload("res://game/mute_state.gd")
const AdPolicy = preload("res://game/ad_policy.gd")
const QaHooks = preload("res://debug/qa_hooks.gd")

func test_mute_any_reason():
	var m = MuteState.new()
	assert_false(m.muted())
	m.set_reason("hidden", true); m.set_reason("ad", true)
	m.set_reason("hidden", false)
	assert_true(m.muted(), "still muted by ad")
	m.set_reason("ad", false)
	assert_false(m.muted())

func test_ad_policy_never_both():
	# tea-bakery replaces the starter's 3-round policy with the chapter policy (tests/test_ad_policy.gd)
	var p = AdPolicy.new(0, 1)
	assert_eq(p.board_end_offer(), "none")
	assert_eq(p.chapter_end_offer(1, 10 * 60 * 1000, false), "none")

func test_query_parse():
	var d = QaHooks.parse_query("?qa=1&level=3&intro=0&name=a%20b")
	assert_eq(d["qa"], "1"); assert_eq(d["level"], "3"); assert_eq(d["intro"], "0"); assert_eq(d["name"], "a b")

## FF lesson: lifecycle code must never pause the tree (boot hang before first frame).
func test_no_tree_pause_in_lifecycle_code():
	for path in ["res://autoload/sfx.gd", "res://autoload/dbg.gd", "res://autoload/pkd_view.gd", "res://scenes/main.gd", "res://pkd_intro/pkd_intro.gd"]:
		var src = FileAccess.get_file_as_string(path)
		assert_false(src.contains("paused = true"), "%s pauses the tree" % path)

## 44px tap targets / 12px text at the 390x844 base (1 viewport px = 1 CSS px at DPR 1).
func _walk(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children(): _walk(c, out)

func test_ui_minimums_main_scene():
	var scene = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(scene)
	await wait_frames(2)
	var nodes: Array = []
	_walk(scene, nodes)
	var checked := 0
	for n in nodes:
		if n is BaseButton and n.is_visible_in_tree():
			assert_gte(n.size.y, 44.0, "%s height %s < 44" % [n.name, n.size.y])
			assert_gte(n.size.x, 44.0, "%s width %s < 44" % [n.name, n.size.x])
			checked += 1
		if n is Label or n is Button:
			var fs = n.get_theme_font_size("font_size")
			assert_gte(fs, 12, "%s font %d < 12" % [n.name, fs])
	assert_gt(checked, 0, "no buttons checked")

func test_intro_and_splash_present():
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/main.tscn")
	assert_eq(ProjectSettings.get_setting("application/boot_splash/image"), "res://pkd_boot_splash_plain.png", "PKD intro v1.1: plain navy splash is the default (N2)")
	assert_true(ProjectSettings.get_setting("application/boot_splash/fullsize"))
	assert_not_null(load("res://pkd_intro/pkd_intro.tscn"))
	assert_not_null(load("res://pkd_intro/pkd_frames.res"), "pkd_intro frames present")
