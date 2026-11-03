## SPEC v1.0.2 D-02 on phones: rules text <= 3 lines at >= 16 px; board >= 352 px; targets >= 44 px; the room comes
## from padding (bubble = 3 x 20 px lines + 2 x 12 px padding), never from font or board size. 390x844 logical.
extends GutTest
const Progress = preload("res://game/progress.gd")
const Cfg = preload("res://game/tt_config.gd")
const UiLayout = preload("res://game/ui_layout.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")

func test_rules_three_lines_board_targets_8x8():
	var m = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	m.progress = Progress.new()
	for ch in range(1, 6): for b in range(1, 13): m.progress.mark_solved("c%d-b%d" % [ch, b])
	m._on_intro_finished()
	assert_true(m.open_board("c6-b2")); await wait_frames(4)
	assert_eq(m.n, 8)
	assert_eq(m.layout_mode_name, "portrait")
	assert_eq(m.hint_label.text, Cfg.RULES_TEXT)
	assert_eq(m.hint_label.get_theme_font_size("font_size"), 16, "rules text 16 px")
	var lines: int = m.hint_label.get_line_count()
	assert_between(lines, 1, 3, "rules text <= 3 lines (got %d)" % lines)
	assert_lte(m.hint_label.get_visible_line_count(), 3)
	assert_eq(m.bubble.custom_minimum_size.y, TtTheme.BUBBLE_3LINE_H if lines >= 3 else TtTheme.BUBBLE_MIN_H)
	assert_gte(m.board.size.x, UiLayout.BOARD_MIN); assert_gte(m.board.size.y, UiLayout.BOARD_MIN)
	assert_gte(m.board.cell_size(), 44.0)
	for c in [m.undo_btn, m.hint_btn, m.reset_btn, m.home_btn, m.settings_btn]:
		if not c.is_visible_in_tree(): continue
		assert_gte(c.size.x, 44.0, c.name); assert_gte(c.size.y, 44.0, c.name)
	assert_false(m.too_small)
