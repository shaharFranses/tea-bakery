## Bakery Logic Puzzle main scene (thin slice, SPEC v1.0.1): PKD intro -> c1-b1 (no menu, D-14) -> tutorial trays
## c1-b1..b3 (givens, coach line, pulsing target) -> c1-b4..b12 -> chapter end (recipe card + décor, midgame slot) -> ch2.
## SPEC v1.1: 8 chapters x 12 levels, numbered 1..96 on the level map; every solved level keeps its best stars (1-3).
## Screens: board, home, recipe_book, chapter_end, all_baked, level_map (+ solved card / settings / rewarded-hint /
## reset-confirm modals).
## Boot routing (TT-AC-23): saved-marks board, else next unsolved chapter board, else Home.
## SDK (§12.1): gameplayStart when a board becomes interactive; gameplayStop on solved card, chapter end, Home, menus,
## settings, any ad, tab hidden; happytime on chapter complete only; midgame only at the chapter-end slot (D-19).
## Save (§12.2): fixed key, debounced 1.0 s, immediate on solve / chapter end / settings / hidden / pagehide.
## Debug builds: URL seed/size give a "free" generated board; QA hooks live in debug/ (never in release).
## Nothing here pauses the tree (FF boot-hang lesson).
extends Control

const PkdIntro := preload("res://pkd_intro/pkd_intro.tscn")
const Gen = preload("res://game/generator.gd")
const Rules = preload("res://game/rules.gd")
const BoardView = preload("res://scenes/board_view.gd")
const Cfg = preload("res://game/tt_config.gd")
const UiLayout = preload("res://game/ui_layout.gd")
const Clock = preload("res://game/clock.gd")
const Daily = preload("res://game/daily.gd")
const AdPolicy = preload("res://game/ad_policy.gd")
const Cells = preload("res://game/cells.gd")
const Settings = preload("res://game/settings.gd")
const TtTheme = preload("res://ui/theme/tt_theme.gd")
const Pal = preload("res://ui/theme/art_palette.gd")
const Chapters = preload("res://game/chapters.gd")
const DailyPool = preload("res://game/daily_pool.gd")
const Progress = preload("res://game/progress.gd")
const Grader = preload("res://game/grader.gd")
const HintText = preload("res://game/hint_text.gd")
const RecipeCard = preload("res://scenes/recipe_card.gd")
const TouchScroll = preload("res://ui/touch_scroll.gd")
const Shelf = preload("res://scenes/shelf.gd")
const StarRow = preload("res://scenes/star_row.gd")

const CARD_MS := 1500            # bake reward + "Baked!" card, then the next board (TT-AC-25: interactive <= 2.0 s)
const SAVE_DEBOUNCE_S := 1.0     # §3.5 save.debounce_ms
const IDLE_PULSE_S := 30.0
const BOOK_CARD_MIN_H := 280.0  # Recipe Book card height floor (ribbon names readable)       # §3.5 hints.idle_pulse_s

var intro_done := false
var n := 5
var seed_value := 1
var puzzle: Dictionary = {}
var moves := 0
var won := false
var taps := 0
var session_start_ms := 0
var mode := "chapter"            # chapter | replay | daily | free (debug generated boards)
var chapter := 0                 # current chapter board (0 = not a chapter board)
var board_no := 0
var daily = Daily.new()
var ad_policy = AdPolicy.new(0, 0)
var save_data: Dictionary = {}
var settings = Settings.new()
var progress = Progress.new()
var board_t0_ms := 0
var last_daily_result: Dictionary = {}
var screen := "board"            # board | home | recipe_book | chapter_end | all_baked | level_map
var screen_log: Array = []       # [screen or board id] in order (TT-AC-05d / -23)
var givens := {}                 # cell index -> true (immutable plated cakes)
var history: Array = []          # undo stack of cell snapshots (not saved)
var undo_count := 0
var active_ms := 0.0             # active play time on this board (excludes hidden tab, ads, solved card)
var interactive := false
var card_open := false
var page_hidden := false
var hint_state := {"free_left": 1, "rewarded_visible": false, "text": "", "technique": "", "targets": [], "pulse_count": 0, "kind": ""}
var hints_used_board := 0
var conflicts_board := 0         # times a new conflict appeared on this board (stars, SPEC v1.1 §3.6)
var last_stars := 0              # stars of the last solve (solved card)
var idle_s := 0.0
var last_chapter_end := 0
var muted := false

const PORTRAIT_BACKDROP_SCREENS := ["home", "recipe_book", "chapter_end", "all_baked", "level_map"]
const BACKDROP_LANDSCAPE := "res://assets/backdrop/backdrop_landscape.webp"   # desktop / wide
const BACKDROP_PORTRAIT := "res://assets/backdrop/backdrop_portrait.webp"     # phone Home / Recipe Book / chapter end
var tex_landscape: Texture2D
var tex_portrait: Texture2D

@onready var margin: MarginContainer = $Margin
var label: Label                 # board title ("Level 14" / "Bake of the Day")
var status: Label
var board: Control
var button: Button               # "New tray" (free/debug boards only)
var mute: Button                 # Sound toggle (Settings modal)
var size_buttons: Array = []
var backdrop: TextureRect
var backdrop_fill: ColorRect
var gameplay_started := false
var layout_mode_name := ""
var vb: VBoxContainer
var wide_root: Control
var panel: VBoxContainer
var sizes: HFlowContainer
var row: HFlowContainer
var hint_label: Label
var top_bar: HBoxContainer
var dots: HBoxContainer
var bubble: PanelContainer
var undo_btn: Button
var hint_btn: Button
var hint_badge: TextureRect
var reset_btn: Button
var showme_btn: Button          # D-07 / HN-20: "Show me" applies the shown hint
var last_hint_step: Dictionary = {}
var too_small := false           # TT-AC-48
var too_small_cover: Control
var home_btn: Button
var settings_btn: Button
var order_btn: Button
var automold_btn: Button
var music_btn: Button
var progress_reset_modal: Control
var settings_flow: HFlowContainer
var save_timer: Timer
var card_timer: Timer
# screens / modals
var home_screen: Control
var book_screen: Control
var end_screen: Control
var solved_card: Control
var modal_root: Control
var settings_modal: Control
var reward_modal: Control
var reset_modal: Control
var home_continue: Button
var home_daily: Button
var home_streak: Label
var home_shelf: Control
var end_title: Label
var end_card: Control
var end_decor: Label
var end_next: Button
var end_home: Button
var end_shelf: Control
var book_grid: GridContainer
var book_scroll: ScrollContainer
var book_cards: Array = []
var home_levels: Button          # level map (SPEC v1.1 §9)
var home_stars: Label
var all_screen: Control
var all_grid: GridContainer
var all_cards: Array = []
var all_shelf: Control
var map_screen: Control          # level map (SPEC v1.1 §9): chapters as groups of 12 numbered levels + stars
var map_box: VBoxContainer
var map_scroll: ScrollContainer
var map_total: Label
var map_buttons := {}            # board id -> Button
var card_title: Label
var card_time: Label
var card_stars: Control
var card_tip: Label
var _js_cbs: Array = []

func _ready() -> void:
	Dbg.main = self
	theme = TtTheme.build()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # @2x sprites + mipmaps (handoff import table)
	session_start_ms = int(Time.get_unix_time_from_system() * 1000.0)
	save_data = Store.load_data()
	daily.from_dict(save_data.get("daily", {}))
	settings.from_dict(save_data.get("settings", {}))
	muted = not settings.sound; Sfx.set_user_muted(muted); Sfx.set_music(settings.music)
	progress.from_dict(save_data.get("progress", {}))
	ad_policy.chapters_completed = progress.chapters_completed
	_build_ui()
	_build_screens()
	_relayout()
	current_date = Clock.local_date()
	var day_timer := Timer.new(); day_timer.name = "DayTimer"; day_timer.wait_time = 5.0; day_timer.autostart = true
	day_timer.timeout.connect(check_day); add_child(day_timer)
	save_timer = Timer.new(); save_timer.name = "SaveTimer"; save_timer.one_shot = true; save_timer.wait_time = SAVE_DEBOUNCE_S
	save_timer.timeout.connect(func(): save_now("debounce")); add_child(save_timer)
	card_timer = Timer.new(); card_timer.name = "CardTimer"; card_timer.one_shot = true; card_timer.wait_time = CARD_MS / 1000.0
	card_timer.timeout.connect(_after_card); add_child(card_timer)
	PkdView.insets_changed.connect(_on_resized)
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_resized)
	_bind_page_events()
	var qs := Dbg.toggle("seed", "")
	var qsize := Dbg.toggle("size", "")
	if qs != "" or qsize != "":
		n = clampi((qsize if qsize != "" else "5").to_int(), Gen.MIN_N, max_size())
		new_board(n, Gen.seed_from_string(qs) if qs != "" else _fresh_seed())
	else:
		var tgt: String = progress.boot_target()
		if tgt == "home": show_home()
		else: open_board(tgt, true)
	var st := Dbg.toggle("state", "")
	if st != "": _preset_state(st)
	Ads.hold(true)            # no SDK call / ad until the intro has finished (SD dev a795a1a boot hold)
	if Dbg.toggle("intro", "1") == "0":
		_on_intro_finished.call_deferred()
	else:
		var intro := PkdIntro.instantiate()
		intro.finished.connect(_on_intro_finished)
		add_child(intro)
	print("[PKD] main ready")

func _fresh_seed() -> int:
	return int(Time.get_unix_time_from_system()) & 0x7FFFFFFF

# ------------------------------------------------------------------ UI
func _round_button(nm: String, icon_name: String, tip: String) -> Button:
	var b := Button.new(); b.name = nm; b.theme_type_variation = "RoundButton"; b.tooltip_text = tip
	b.custom_minimum_size = Vector2(56, 56); b.icon = TtTheme.icon(icon_name); b.expand_icon = true
	return b

func _tool_button(nm: String, text: String, icon_name: String, variation := "", parent: Control = null) -> Button:
	var b := Button.new(); b.name = nm; b.text = text
	b.theme_type_variation = variation
	if icon_name != "": b.icon = TtTheme.icon(icon_name, variation != "")   # cream icons on raspberry / sage
	b.custom_minimum_size = Vector2(0, 48)              # spec: buttons >= 48 px tall
	(parent if parent else row).add_child(b)
	return b

## Settings toggle: toggle_on / toggle_off sprite (64x36) right of the label; the label never changes.
func _toggle_button(nm: String, text: String, parent: Control) -> Button:
	var b := Button.new(); b.name = nm; b.text = text; b.toggle_mode = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_constant_override("icon_max_width", 48)
	b.custom_minimum_size = Vector2(220, 48)
	b.toggled.connect(func(on): b.icon = TtTheme.ui_tex("toggle_on" if on else "toggle_off"))
	b.icon = TtTheme.ui_tex("toggle_off")
	parent.add_child(b)
	return b

func _build_ui() -> void:
	backdrop_fill = ColorRect.new(); backdrop_fill.name = "BackdropFill"
	backdrop_fill.color = Pal.ROSEWATER_BG; backdrop_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop_fill); move_child(backdrop_fill, 1)
	backdrop = TextureRect.new(); backdrop.name = "Backdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # backdrops: lossy webp, no mipmaps
	tex_landscape = load(BACKDROP_LANDSCAPE)
	tex_portrait = load(BACKDROP_PORTRAIT)
	add_child(backdrop); move_child(backdrop, 2)
	vb = VBoxContainer.new(); vb.name = "VBox"
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	# top bar 56: Home, title, Settings
	top_bar = HBoxContainer.new(); top_bar.name = "TopBar"; top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 8)
	vb.add_child(top_bar)
	home_btn = _round_button("Home", "home", "Home")
	home_btn.pressed.connect(func(): show_home())
	top_bar.add_child(home_btn)
	label = Label.new(); label.name = "Title"; label.text = Cfg.TITLE_PLACEHOLDER
	label.theme_type_variation = "TitleLabel"; label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	top_bar.add_child(label)
	settings_btn = _round_button("Settings", "settings", "Settings")
	settings_btn.pressed.connect(func(): open_settings())
	top_bar.add_child(settings_btn)
	bubble = PanelContainer.new(); bubble.name = "RulesBubble"; bubble.theme_type_variation = "CoachBubble"
	bubble.custom_minimum_size.y = TtTheme.BUBBLE_MIN_H
	vb.add_child(bubble)
	hint_label = Label.new(); hint_label.name = "Hint"
	hint_label.text = Cfg.RULES_TEXT
	hint_label.theme_type_variation = "BubbleLabel"   # D-02: rules 16 px Lexend, up to 3 lines on phones (ruling 10:19)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.max_lines_visible = 3
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint_label.resized.connect(_fit_bubble)
	bubble.add_child(hint_label)
	dots = HBoxContainer.new(); dots.name = "ChapterDots"; dots.add_theme_constant_override("separation", 6)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 5)
	for k in Chapters.BOARDS:
		var d := TextureRect.new(); d.name = "Dot%d" % k; d.custom_minimum_size = Vector2(14, 14)
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dots.add_child(d)
	vb.add_child(dots)
	sizes = HFlowContainer.new(); sizes.name = "Sizes"
	sizes.alignment = FlowContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override("h_separation", 8); sizes.add_theme_constant_override("v_separation", 8)
	vb.add_child(sizes)
	for k in range(Gen.MIN_N, Gen.MAX_N + 1):
		var b := Button.new(); b.name = "Size%d" % k; b.text = "%dx%d" % [k, k]
		b.custom_minimum_size = Vector2(60, 44); b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("n", k)
		b.pressed.connect(func(): new_board(k, _fresh_seed()))
		sizes.add_child(b); size_buttons.append(b)
	board = BoardView.new(); board.name = "Board"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(UiLayout.BOARD_MIN, UiLayout.BOARD_MIN)
	board.cell_tapped.connect(tap_cell)
	board.cell_right_clicked.connect(right_click_cell)
	board.resized.connect(_update_size_buttons)
	board.resized.connect(func(): _check_too_small.call_deferred())
	too_small_cover = PanelContainer.new(); too_small_cover.name = "TooSmall"; too_small_cover.visible = false
	too_small_cover.theme_type_variation = "CardPanel"
	too_small_cover.set_anchors_preset(Control.PRESET_FULL_RECT); too_small_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var tsl := Label.new(); tsl.name = "TooSmallText"; tsl.text = "Turn your device upright or enlarge the window to play this tray."
	tsl.add_theme_font_size_override("font_size", 16); tsl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tsl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tsl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	too_small_cover.add_child(tsl); board.add_child(too_small_cover)
	vb.add_child(board)
	status = Label.new(); status.name = "Status"
	status.add_theme_font_size_override("font_size", 16)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(status)
	row = HFlowContainer.new(); row.name = "Buttons"
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 8); row.add_theme_constant_override("v_separation", 8)
	vb.add_child(row)
	undo_btn = _tool_button("Undo", "Undo", "undo")
	undo_btn.pressed.connect(undo)
	hint_btn = _tool_button("HintButton", "Hint", "hint")
	hint_btn.pressed.connect(request_hint)
	hint_badge = TextureRect.new(); hint_badge.name = "HintBadge"; hint_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; hint_badge.size = Vector2(24, 24)
	hint_btn.add_child(hint_badge)
	hint_btn.resized.connect(func(): hint_badge.position = Vector2(hint_btn.size.x - 18, -6))
	showme_btn = _tool_button("ShowMe", "Show me", "hint")
	showme_btn.pressed.connect(func(): apply_hint())
	showme_btn.visible = false
	reset_btn = _tool_button("Clear", "Reset", "reset")
	reset_btn.pressed.connect(request_reset)
	button = _tool_button("Play", "New tray", "play", "PrimaryButton")
	button.pressed.connect(func(): taps += 1; new_board(n, _fresh_seed()))
	wide_root = Control.new(); wide_root.name = "Wide"; wide_root.visible = false
	wide_root.set_anchors_preset(Control.PRESET_FULL_RECT); wide_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wide_root)
	panel = VBoxContainer.new(); panel.name = "Panel"
	panel.add_theme_constant_override("separation", 8)
	panel.minimum_size_changed.connect(func(): if layout_mode_name == "wide": _fit_panel.call_deferred())
	wide_root.add_child(panel)

## Full-screen page: backdrop shows through; a centred column (<= 480 wide) inside safe margins.
func _page(nm: String) -> Dictionary:
	var root := MarginContainer.new(); root.name = nm; root.visible = false
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var col := VBoxContainer.new(); col.name = "Column"; col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.custom_minimum_size.x = 320
	root.add_child(col)
	return {"root": root, "col": col}

func _title(text: String, nm: String, size_px := 28) -> Label:
	var l := Label.new(); l.name = nm; l.text = text; l.theme_type_variation = "TitleLabel"
	l.add_theme_font_size_override("font_size", size_px)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _modal(nm: String) -> Dictionary:
	var root := Control.new(); root.name = nm; root.visible = false
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(root)
	var scrim := ColorRect.new(); scrim.color = Pal.SCRIM; scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scrim)
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(cc)
	var p := PanelContainer.new(); p.theme_type_variation = "ModalPanel"; cc.add_child(p)
	var col := VBoxContainer.new(); col.add_theme_constant_override("separation", 12); col.custom_minimum_size.x = 280
	p.add_child(col)
	return {"root": root, "col": col}

func _body(text: String, nm: String) -> Label:
	var l := Label.new(); l.name = nm; l.text = text; l.add_theme_font_size_override("font_size", 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _build_screens() -> void:
	# Home (§9: Continue / Bake of the Day / Recipe Book / Settings; counter shelf with décor; streak)
	var h := _page("HomeScreen"); home_screen = h.root
	h.col.add_child(_title(Cfg.TITLE_PLACEHOLDER, "HomeTitle", 32))
	home_shelf = Shelf.new(); home_shelf.name = "HomeShelf"; home_shelf.custom_minimum_size = Vector2(320, 142)
	h.col.add_child(home_shelf)
	home_streak = _body("", "HomeStreak"); h.col.add_child(home_streak)
	home_stars = _body("", "HomeStars"); home_stars.add_theme_font_size_override("font_size", 14); h.col.add_child(home_stars)
	home_continue = _tool_button("HomeContinue", "Continue", "play", "PrimaryButton", h.col)
	home_continue.pressed.connect(home_continue_pressed)
	home_daily = _tool_button("HomeDaily", "Bake of the Day", "streak", "SecondaryButton", h.col)
	home_daily.pressed.connect(func(): if open_daily(Clock.local_date()): pass)
	home_levels = _tool_button("HomeLevels", "Levels", "check", "", h.col)
	home_levels.pressed.connect(func(): show_level_map())
	var hb := _tool_button("HomeRecipeBook", "Recipe Book", "book", "", h.col)
	hb.pressed.connect(func(): show_recipe_book())
	var hs := _tool_button("HomeSettings", "Settings", "settings", "", h.col)
	hs.pressed.connect(func(): open_settings())
	# Recipe Book (8 cards)
	var r := _page("RecipeBook"); book_screen = r.root
	var rb := HBoxContainer.new(); rb.add_theme_constant_override("separation", 8); r.col.add_child(rb)
	var back := _round_button("BookBack", "back", "Back"); back.pressed.connect(func(): show_home()); rb.add_child(back)
	var bt := _title("Recipe Book", "BookTitle", 24); bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rb.add_child(bt)
	book_scroll = TouchScroll.new(); book_scroll.name = "BookScroll"
	book_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r.col.add_child(book_scroll)
	book_grid = GridContainer.new(); book_grid.name = "BookGrid"; book_grid.columns = 2
	book_grid.add_theme_constant_override("h_separation", 8); book_grid.add_theme_constant_override("v_separation", 8)
	book_scroll.add_child(book_grid)
	for ch in range(1, 9):
		var c := RecipeCard.new(); c.name = "Card%d" % ch; book_grid.add_child(c); c.setup(ch, false); book_cards.append(c)
	# Chapter end (§7: recipe card flips in, décor drops onto the shelf; "Next chapter" primary + "Home")
	var e := _page("ChapterEnd"); end_screen = e.root
	end_title = _title("", "EndTitle", 26); e.col.add_child(end_title)
	end_card = RecipeCard.new(); end_card.name = "EndCard"; e.col.add_child(end_card); end_card.setup(1, true)
	end_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_shelf = Shelf.new(); end_shelf.name = "EndShelf"; end_shelf.custom_minimum_size = Vector2(320, 142); e.col.add_child(end_shelf)
	end_decor = _body("", "EndDecor"); e.col.add_child(end_decor)
	var eb := HBoxContainer.new(); eb.name = "EndButtons"; eb.add_theme_constant_override("separation", 12)
	eb.alignment = BoxContainer.ALIGNMENT_CENTER; e.col.add_child(eb)
	end_next = _tool_button("EndNext", "Next chapter", "play", "PrimaryButton", eb)
	end_next.pressed.connect(func(): chapter_end_continue("next"))
	end_home = _tool_button("EndHome", "Home", "home", "", eb)
	end_home.pressed.connect(func(): chapter_end_continue("home"))
	# All recipes baked (§7.2, TT-AC-51): 8-card spread + full shelf + one line + one "Home" button, shown once
	var a := _page("AllBaked"); all_screen = a.root
	a.col.add_child(_title("All recipes baked", "AllTitle", 26))
	all_grid = GridContainer.new(); all_grid.name = "AllGrid"; all_grid.columns = 4
	all_grid.add_theme_constant_override("h_separation", 6); all_grid.add_theme_constant_override("v_separation", 6)
	all_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; a.col.add_child(all_grid)
	for ch in range(1, 9):
		var c := RecipeCard.new(); c.name = "AllCard%d" % ch; all_grid.add_child(c); c.compact = true; c.setup(ch, true); all_cards.append(c)
	all_shelf = Shelf.new(); all_shelf.name = "AllShelf"; all_shelf.custom_minimum_size = Vector2(320, 142); a.col.add_child(all_shelf)
	a.col.add_child(_body("New trays every day in Bake of the Day.", "AllLine"))
	var ah := _tool_button("AllHome", "Home", "home", "PrimaryButton", a.col)
	ah.pressed.connect(func(): show_home())
	# Level map (SPEC v1.1 §9): one group per chapter (title + stars), 12 numbered level buttons with their best stars.
	# Solved levels replay (no rewards, events or midgame); the first unsolved level plays; later levels are locked.
	var lm := _page("LevelMap"); map_screen = lm.root
	var lb := HBoxContainer.new(); lb.add_theme_constant_override("separation", 8); lm.col.add_child(lb)
	var lback := _round_button("MapBack", "back", "Back"); lback.pressed.connect(func(): show_home()); lb.add_child(lback)
	var lt := _title("Levels", "MapTitle", 24); lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lb.add_child(lt)
	map_total = _body("", "MapTotal"); map_total.add_theme_font_size_override("font_size", 14)
	map_total.custom_minimum_size.x = 56; lb.add_child(map_total)
	map_scroll = TouchScroll.new(); map_scroll.name = "MapScroll"; map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; lm.col.add_child(map_scroll)
	lm.col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_box = VBoxContainer.new(); map_box.name = "MapBox"; map_box.add_theme_constant_override("separation", 8)
	map_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mpad := MarginContainer.new(); mpad.name = "MapPad"; mpad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mpad.add_theme_constant_override("margin_right", 14)   # keep the right column clear of the scrollbar
	map_scroll.add_child(mpad); mpad.add_child(map_box)
	for ch in range(1, Chapters.count_available() + 1):
		var hh := HBoxContainer.new(); hh.name = "MapHead%d" % ch; hh.alignment = BoxContainer.ALIGNMENT_CENTER
		hh.add_theme_constant_override("separation", 6); map_box.add_child(hh)
		var ci := TextureRect.new(); ci.name = "MapCake%d" % ch; ci.custom_minimum_size = Vector2(32, 32)   # the chapter's cake
		ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ci.texture = load("res://assets/board/cake_%s@2x.png" % Chapters.cake_for(ch)); hh.add_child(ci)
		var hl := _body("", "MapCh%d" % ch); hl.theme_type_variation = "TitleLabel"; hl.add_theme_font_size_override("font_size", 18)
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; hh.add_child(hl)
		var grid := GridContainer.new(); grid.name = "MapGrid%d" % ch; grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; map_box.add_child(grid)
		for b in range(1, Chapters.BOARDS + 1):
			var id := "c%d-b%d" % [ch, b]
			var bb := Button.new(); bb.name = "Level_%s" % id.replace("-", "_"); bb.custom_minimum_size = Vector2(72, 72)
			bb.tooltip_text = "Level %d" % Chapters.level(ch, b)
			var v := VBoxContainer.new(); v.set_anchors_preset(Control.PRESET_FULL_RECT); v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", 2); bb.add_child(v)
			var nl := Label.new(); nl.name = "Num"; nl.text = str(Chapters.level(ch, b)); nl.add_theme_font_size_override("font_size", 20)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; nl.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(nl)
			var sr := StarRow.new(); sr.name = "Stars"; sr.custom_minimum_size = Vector2(56, 14); v.add_child(sr)
			bb.pressed.connect(func(): open_level(id)); grid.add_child(bb)
			map_buttons[id] = bb
	# modal layer (over everything except the intro)
	modal_root = Control.new(); modal_root.name = "Modals"; modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_root)
	# solved card: "Baked!" + active time; tap anywhere skips (TT-AC-25)
	solved_card = Control.new(); solved_card.name = "SolvedCard"; solved_card.visible = false
	solved_card.set_anchors_preset(Control.PRESET_FULL_RECT); modal_root.add_child(solved_card)
	solved_card.gui_input.connect(_on_card_input)
	var scc := CenterContainer.new(); scc.set_anchors_preset(Control.PRESET_FULL_RECT); scc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	solved_card.add_child(scc)
	var scp := PanelContainer.new(); scp.theme_type_variation = "CardPanel"; scp.mouse_filter = Control.MOUSE_FILTER_IGNORE; scc.add_child(scp)
	var scv := VBoxContainer.new(); scv.mouse_filter = Control.MOUSE_FILTER_IGNORE; scp.add_child(scv)
	card_title = _title("Baked!", "CardTitle", 32); card_title.custom_minimum_size.x = 200; scv.add_child(card_title)
	card_stars = StarRow.new(); card_stars.name = "CardStars"; card_stars.custom_minimum_size = Vector2(150, 40); scv.add_child(card_stars)
	card_time = _body("", "CardTime"); card_time.add_theme_font_size_override("font_size", 14); scv.add_child(card_time)
	card_tip = _body("", "CardTip"); card_tip.add_theme_font_size_override("font_size", 14); card_tip.custom_minimum_size.x = 240
	scv.add_child(card_tip)
	# settings (§9: Sound, Auto-molds, Tap order)
	var s := _modal("SettingsModal"); settings_modal = s.root
	s.col.add_child(_title("Settings", "SettingsTitle", 24))
	settings_flow = HFlowContainer.new(); settings_flow.name = "SettingsToggles"
	settings_flow.add_theme_constant_override("h_separation", 12); settings_flow.add_theme_constant_override("v_separation", 8)
	s.col.add_child(settings_flow)
	mute = _toggle_button("Sound", "Sound", settings_flow)
	mute.toggled.connect(func(on): set_sound(on))
	music_btn = _toggle_button("Music", "Music", settings_flow)
	music_btn.toggled.connect(func(on): set_music(on))
	order_btn = _toggle_button("TapOrder", "Cake first", settings_flow)
	order_btn.toggled.connect(func(on): set_tap_order(Cells.ORDER_CAKE_FIRST if on else Cells.ORDER_MOLD_FIRST))
	automold_btn = _toggle_button("AutoMolds", "Auto-molds", settings_flow)
	automold_btn.toggled.connect(func(on): set_auto_mold(on))
	var rp := _tool_button("ResetProgress", "Reset progress", "reset", "", s.col)
	rp.pressed.connect(func(): progress_reset_modal.visible = true)
	var sc := _tool_button("SettingsClose", "Close", "close", "PrimaryButton", s.col)
	sc.pressed.connect(close_settings)
	# rewarded hint confirm (D-19: equal-size "Watch" / "No thanks", non-green watch button)
	var w := _modal("RewardModal"); reward_modal = w.root
	w.col.add_child(_body("Watch a short ad for one more hint?", "RewardText"))
	var wr := HBoxContainer.new(); wr.add_theme_constant_override("separation", 12); wr.alignment = BoxContainer.ALIGNMENT_CENTER; w.col.add_child(wr)
	var watch := _tool_button("RewardWatch", "Watch", "rewarded", "PrimaryButton", wr)
	var nothx := _tool_button("RewardNo", "No thanks", "", "", wr)
	for b in [watch, nothx]: b.custom_minimum_size = Vector2(130, 56)
	watch.pressed.connect(func(): _watch_for_hint())
	nothx.pressed.connect(func(): reward_modal.visible = false)
	# reset confirm (TT-AC-15)
	var rs := _modal("ResetModal"); reset_modal = rs.root
	rs.col.add_child(_body("Clear every cake and mold on this tray?", "ResetText"))
	var rr := HBoxContainer.new(); rr.add_theme_constant_override("separation", 12); rr.alignment = BoxContainer.ALIGNMENT_CENTER; rs.col.add_child(rr)
	var cancel := _tool_button("ResetCancel", "Cancel", "", "", rr)
	var ok := _tool_button("ResetOk", "Reset", "reset", "PrimaryButton", rr)
	for b in [cancel, ok]: b.custom_minimum_size = Vector2(120, 48)
	cancel.pressed.connect(func(): reset_modal.visible = false)
	ok.pressed.connect(func(): reset_modal.visible = false; clear_board())
	# reset progress confirm (§9; QA-A04): clears chapter progress, cards/décor and Bake of the Day history; settings kept
	var rpm := _modal("ProgressResetModal"); progress_reset_modal = rpm.root
	rpm.col.add_child(_body("Start over? Every recipe card, décor piece and streak will be cleared. Your settings stay.", "ProgressResetText"))
	var rpr := HBoxContainer.new(); rpr.add_theme_constant_override("separation", 12); rpr.alignment = BoxContainer.ALIGNMENT_CENTER; rpm.col.add_child(rpr)
	var rpc := _tool_button("ProgressResetCancel", "Cancel", "", "", rpr)
	var rpo := _tool_button("ProgressResetOk", "Start over", "reset", "PrimaryButton", rpr)
	for b in [rpc, rpo]: b.custom_minimum_size = Vector2(120, 48)
	rpc.pressed.connect(func(): progress_reset_modal.visible = false)
	rpo.pressed.connect(func(): reset_progress())
	_sync_setting_buttons()

# ------------------------------------------------------------------ screens
func _set_screen_raw(s: String) -> void:
	screen = s
	var on_board := s == "board"
	margin.visible = on_board and layout_mode_name != "wide"
	wide_root.visible = on_board and layout_mode_name == "wide"
	home_screen.visible = s == "home"; book_screen.visible = s == "recipe_book"; end_screen.visible = s == "chapter_end"
	all_screen.visible = s == "all_baked"; map_screen.visible = s == "level_map"
	screen_log.append(s if not on_board else board_id())
	if screen_log.size() > 100: screen_log.pop_front()
	_apply_safe_area()
	Dbg.hit("screen %s" % (s if not on_board else "board " + board_id()))

## Screen switch (+ backdrop): menus stop gameplay (CG gameplayStop).
func set_screen(s: String) -> void:
	_set_screen_raw(s)
	if s != "board":
		interactive = false
		if intro_done: Ads.set_context("menu")

func show_home() -> void:
	if card_open: _close_card()
	save_now("home")
	_refresh_home()
	set_screen("home")

func _refresh_home() -> void:
	var tgt: String = progress.next_unsolved()
	var has_marks: bool = progress.current_id != "" and not progress.is_solved(progress.current_id)
	home_continue.visible = tgt != "" or has_marks
	var cont_id: String = progress.current_id if has_marks else tgt
	home_continue.text = "Play" if progress.solved.is_empty() and not has_marks else ("Continue · Level %d" % Chapters.level_of(cont_id) if cont_id != "" else "Continue")
	var unlocked: bool = progress.chapter_done(1)
	var done := daily.is_done(Clock.local_date())
	home_daily.disabled = not unlocked or done
	home_daily.text = "Baked · back tomorrow" if done else "Bake of the Day"
	home_daily.icon = TtTheme.icon("check" if done else "streak", true)
	# §7.2: once every chapter is done, Bake of the Day is the primary button ("Levels" replaces "Replay a chapter", v1.1)
	var all_done: bool = progress.all_done()
	home_daily.theme_type_variation = "PrimaryButton" if all_done else "SecondaryButton"
	home_daily.text = "Baked ✓ · back tomorrow" if done and all_done else home_daily.text
	home_levels.visible = not progress.solved.is_empty()
	home_stars.text = "Stars: %d / %d" % [progress.total_stars(), Progress.max_stars()]
	home_stars.visible = not progress.solved.is_empty()
	var sm: Dictionary = daily.summary(Clock.local_date())
	home_streak.text = "Streak: %d · Best: %d" % [sm.streak, sm.best_streak] if unlocked else "Finish chapter 1 to unlock Bake of the Day."
	home_shelf.set_owned(progress.decor)

func home_continue_pressed() -> void:
	var id: String = progress.current_id if progress.current_id != "" and not progress.is_solved(progress.current_id) else progress.next_unsolved()
	if id != "": open_board(id, true)

func show_recipe_book() -> void:
	for c in book_cards:
		c.unlocked = c.chapter in progress.recipes; c.refresh()
	set_screen("recipe_book")

func open_settings() -> void:
	_sync_setting_buttons()
	settings_modal.visible = true
	if intro_done: Ads.set_context("menu")     # gameplayStop while Settings is open (TT-AC-31)

func close_settings() -> void:
	settings_modal.visible = false
	if screen == "board" and intro_done and interactive and not won: Ads.set_context("play")

# ------------------------------------------------------------------ boards
## Open a chapter board "cN-bM" (restore: re-apply saved marks if this is the saved board).
func open_board(id: String, restore := false) -> bool:
	var cb := Chapters.parse_id(id)
	var p := Chapters.board(cb[0], cb[1])
	if p.is_empty(): return false
	if card_open: _close_card()
	chapter = cb[0]; board_no = cb[1]
	mode = "replay" if progress.is_solved(id) else "chapter"
	n = p.n; seed_value = p.seed
	_set_puzzle(p)
	if restore and progress.current_id == id and progress.current_cells.size() == n * n:
		for i in n * n:
			if not givens.has(i): board.cells[i] = int(progress.current_cells[i])
		_refresh()
	progress.current_id = id if mode == "chapter" else progress.current_id
	_set_screen_raw("board")
	Dbg.hit("board %s (%dx%d g%d%s)" % [id, n, n, p.grade, ", replay" if mode == "replay" else ""])
	return true

func new_board(size: int, s: int) -> void:
	n = clampi(size, Gen.MIN_N, max_size()); seed_value = s; mode = "free"; chapter = 0; board_no = 0
	_set_puzzle(Gen.generate(n, s))
	_set_screen_raw("board")
	Dbg.hit("board n=%d seed=%d (%.0f ms, %d reshapes)" % [n, s, puzzle.ms, puzzle.reshapes])

func load_tutorial() -> void:
	open_board("c1-b1")

## Bake of the Day for `date` (device-local; fixed when OPENED, U1/V9). Returns false if already done (not replayable).
func open_daily(date: String) -> bool:
	if not daily.open(date):
		Dbg.hit("daily %s already baked: not replayable" % date)
		return false
	if card_open: _close_card()
	_mark_transition_start()
	var p := DailyPool.board(date)          # pool[(date - epoch) mod 400] (D-11)
	n = p.n; seed_value = p.seed; mode = "daily"; chapter = 0; board_no = 0
	_set_puzzle(p)
	_set_screen_raw("board")
	Dbg.hit("daily %s open n=%d" % [date, n])
	return true

## Daily completion -> streak (U1). forced_date: QA re-fire for V8 (counts at most once per date).
func complete_daily(forced_date: String = "") -> Dictionary:
	last_daily_result = daily.complete(Clock.local_date(), forced_date)
	if last_daily_result.counted:
		Analytics.daily_complete(last_daily_result.date, n, active_ms / 1000.0, hints_used_board, last_daily_result.streak)
	save_now("daily")
	Dbg.hit("daily complete %s" % JSON.stringify(last_daily_result))
	return last_daily_result

func _set_puzzle(p: Dictionary) -> void:
	if intro_done: _mark_transition_start()
	puzzle = p
	givens = {}
	for g in p.get("givens", []): givens[g.x * n + g.y] = true
	board.setup(n, puzzle.regions, p.get("givens", []), board_cake())
	for i in givens: board.cells[i] = Cells.CAKE
	moves = 0; won = false; history.clear(); undo_count = 0; active_ms = 0.0
	hints_used_board = 0; conflicts_board = 0; idle_s = 0.0
	ad_policy.on_board_start()
	hint_state = {"free_left": 1, "rewarded_visible": false, "text": "", "technique": "", "targets": [], "pulse_count": 0, "kind": ""}
	last_hint_step = {}; showme_btn.visible = false
	interactive = false
	_check_too_small.call_deferred()
	_update_size_buttons()
	_sync_board_chrome()
	_refresh()
	if intro_done: _board_interactive.call_deferred()

## Title, dots, coach/rules bubble, tool row per mode.
func _sync_board_chrome() -> void:
	match mode:
		"chapter", "replay": label.text = "Level %d" % Chapters.level(chapter, board_no)
		"daily": label.text = "Bake of the Day"
		_: label.text = Cfg.TITLE_PLACEHOLDER
	dots.visible = chapter > 0
	for k in dots.get_child_count():
		var on: bool = chapter > 0 and (progress.is_solved("c%d-b%d" % [chapter, k + 1]) or k + 1 < board_no)
		(dots.get_child(k) as TextureRect).texture = TtTheme.ui_tex("progress_dot_on" if on else "progress_dot_off")
	sizes.visible = mode == "free"; button.visible = mode == "free"
	board.hint_target = {}; board.hint_unit = {}
	var coach := str(puzzle.get("coach", ""))
	hint_label.text = coach if coach != "" else Cfg.RULES_TEXT
	if coach != "":
		for t in puzzle.get("targets", []): board.hint_target[t.x * n + t.y] = true   # pulsing target cell (§6)
	_sync_hint_button()

## Largest board for this device: 8 on phones/touch, 9 on desktop only if 9x9 cells stay >= 44 px.
func max_size() -> int:
	var mobile := OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")
	if OS.has_feature("web") and not mobile:
		mobile = str(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches ? 'y' : 'n'")) == "y"
	elif not OS.has_feature("web"):
		mobile = mobile or DisplayServer.is_touchscreen_available()
	if mobile: return Gen.MAX_N_MOBILE
	var side: float = board.board_rect().size.x if board and board.size.x > 0 else 0.0
	if side > 0.0 and side / float(Gen.MAX_N) < Cfg.MIN_TAP_PX: return Gen.MAX_N_MOBILE
	return Gen.MAX_N

func _update_size_buttons() -> void:
	var mx := max_size()
	for b in size_buttons:
		b.visible = b.get_meta("n") <= mx
		b.button_pressed = b.get_meta("n") == n

# ------------------------------------------------------------------ layout
var _in_relayout := false
func _page_css() -> Vector2:
	var w := get_window()
	var px := Vector2(w.size)
	var dpr := 1.0
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		dpr = float(v) if v != null else 1.0
	return px / maxf(dpr, 0.01)

func _relayout() -> void:
	if _in_relayout: return
	_in_relayout = true
	var css := _page_css()
	var ls := UiLayout.logical_size(css)
	var w := get_window()
	if Vector2i(ls) != w.content_scale_size: w.content_scale_size = Vector2i(ls)
	var m := UiLayout.mode(css)
	if m != layout_mode_name:
		layout_mode_name = m
		var movers := [top_bar, bubble, dots, sizes, board, status, row]
		for c in movers: c.get_parent().remove_child(c)
		if m == "wide":
			wide_root.add_child(board)
			for c in [top_bar, dots, bubble, status, row, sizes]: panel.add_child(c)
			board.size_flags_vertical = Control.SIZE_FILL
		else:
			for c in movers: vb.add_child(c)
			board.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Dbg.hit("layout %s css=%dx%d logical=%dx%d" % [m, css.x, css.y, ls.x, ls.y])
	margin.visible = screen == "board" and m == "portrait"; wide_root.visible = screen == "board" and m == "wide"
	var vs := get_viewport_rect().size
	if m == "wide":
		var sp := UiLayout.wide_split(vs, PkdView.safe_margins())
		board.custom_minimum_size = Vector2.ZERO
		board.position = sp.board.position; board.size = sp.board.size
		panel_rect = sp.panel
		for c in [sizes, row, status, bubble, top_bar]: c.custom_minimum_size.x = sp.panel.size.x
		_fit_panel()
		_fit_panel.call_deferred()
	else:
		board.custom_minimum_size = Vector2(UiLayout.BOARD_MIN, UiLayout.BOARD_MIN)
		for c in [sizes, row, status, bubble, top_bar]: c.custom_minimum_size.x = 0
		vb.add_theme_constant_override("separation", UiLayout.portrait_gap(vs.y))
	# Recipe Book: 2 columns portrait / 4 wide, cards at least BOOK_CARD_MIN_H tall so every name fits its ribbon
	# (auto-fit, >= 12 px); the grid scrolls vertically when 8 cards do not fit (phones, the 800x450 embed)
	var hs := page_card_heights(vs, m)
	book_grid.columns = hs.cols; var cols: int = hs.cols
	for c in book_cards: c.custom_minimum_size = Vector2(hs.book * 0.75, hs.book)
	book_scroll.custom_minimum_size = Vector2(cols * hs.book * 0.75 + 8.0 * (cols - 1), vs.y - 32.0 - 56.0 - 12.0)
	end_card.custom_minimum_size = Vector2(hs.end * 0.75, hs.end)
	# All recipes baked: 4x2 spread on phones, one row of 8 on wide; the full shelf is always shown (§7.2)
	var acols := 8 if m == "wide" else 4; var arows := 8 / acols
	all_grid.columns = acols
	var aw := minf(vs.x - 32.0, 480.0 if m == "portrait" else 760.0)
	var spare_h := vs.y - 32.0 - 34.0 - 48.0 - 24.0 - 142.0 - 6.0 * (arows - 1) - 12.0 * 4
	var ah := minf((aw - 6.0 * (acols - 1)) / acols * 320.0 / 240.0, spare_h / arows)
	for c in all_cards: c.custom_minimum_size = Vector2(ah * 0.75, ah)
	end_shelf.visible = m == "portrait"
	for ch in range(1, Chapters.count_available() + 1):   # level map: 4 per row on phones, 6 on wide
		(map_box.get_node("MapGrid%d" % ch) as GridContainer).columns = 6 if m == "wide" else 4
	settings_flow.custom_minimum_size.x = 452.0 if m == "wide" else 220.0   # 2 toggles per row on wide (fits 800x450)
	var short := vs.y < 600.0                      # e.g. the 800x450 CrazyGames embed: compact Home
	home_shelf.custom_minimum_size.y = 90.0 if short else 142.0
	home_screen.get_node("Column").add_theme_constant_override("separation", 6 if short else 12)
	end_screen.get_node("Column").add_theme_constant_override("separation", 6 if short else 12)
	_fit_bubble()
	_check_too_small.call_deferred()
	_in_relayout = false

## Recipe-card heights for a viewport (logical px) and layout mode: {book, end}. Shared with tests (ribbon fit).
static func page_card_heights(vs: Vector2, m: String) -> Dictionary:
	# Recipe Book: as many columns as keep cards >= BOOK_CARD_MIN_H (2-line names at the 14 px label minimum); scrolls.
	var max_w := minf(vs.x - 32.0, 480.0 if m == "portrait" else vs.x - 32.0)
	var cols := 4
	while cols > 1 and (max_w - 8.0 * (cols - 1)) / cols * 320.0 / 240.0 < BOOK_CARD_MIN_H: cols -= 1
	var rows := ceili(8.0 / cols)
	var avail_h := vs.y - 32.0 - 56.0 - 12.0 - 8.0 * (rows - 1)
	var book := minf((max_w - 8.0 * (cols - 1)) / cols * 320.0 / 240.0, maxf(avail_h / rows, BOOK_CARD_MIN_H))
	# Chapter end: Next + Home share one row (EndButtons)
	var end_h := clampf(vs.y - 32.0 - 40.0 - 142.0 - 24.0 - 48.0 - 12.0 * 4, 150.0, 300.0)
	if m == "wide": end_h = clampf(vs.y - 24.0 - 40.0 - 48.0 - (6.0 if vs.y < 600.0 else 12.0) * 3 - 24.0, 150.0, 300.0)
	return {"book": book, "end": end_h, "cols": cols}

var panel_rect := Rect2()
func _fit_panel() -> void:
	if layout_mode_name != "wide": return
	panel.size = Vector2(panel_rect.size.x, 0)
	panel.size = Vector2(panel_rect.size.x, maxf(panel.get_combined_minimum_size().y, 0))
	panel.position = Vector2(panel_rect.position.x, panel_rect.position.y + maxf(0.0, (panel_rect.size.y - panel.size.y) / 2.0))

func _fit_bubble() -> void:
	if bubble == null: return
	var h: float = TtTheme.BUBBLE_3LINE_H if hint_label.get_line_count() >= 3 else TtTheme.BUBBLE_MIN_H
	if layout_mode_name == "wide": h = 0.0
	if bubble.custom_minimum_size.y != h: bubble.custom_minimum_size.y = h

func _on_resized() -> void:
	_relayout()
	_apply_safe_area()
	_update_size_buttons()

func _apply_safe_area() -> void:
	var m = PkdView.safe_margins()
	var vs := get_viewport_rect().size
	var side := maxf(16.0, (vs.x - UiLayout.PORTRAIT_MAX_W) / 2.0)
	for mc in [margin, home_screen, book_screen, end_screen, map_screen]:
		if mc == null: continue
		var sd := side if (mc == margin or layout_mode_name != "wide") else 16.0   # wide pages use the full width
		mc.add_theme_constant_override("margin_top", int(16 + m[0]))
		mc.add_theme_constant_override("margin_right", int(sd + m[1]))
		mc.add_theme_constant_override("margin_bottom", int(16 + m[2]))
		mc.add_theme_constant_override("margin_left", int(sd + m[3]))
	_apply_backdrop(vs.x > vs.y)

## Backdrops (handoff P2): landscape webp on desktop / wide; portrait webp (cover-fit, anchored top) on phone Home,
## Recipe Book and chapter end; the phone board screen keeps the flat rosewater wallpaper (calm behind the tray).
func _apply_backdrop(landscape: bool) -> void:
	if backdrop == null: return
	backdrop_fill.visible = true
	var t: Texture2D = null
	if landscape: t = tex_landscape
	elif screen in PORTRAIT_BACKDROP_SCREENS: t = tex_portrait
	backdrop.texture = t
	backdrop.visible = t != null
	if t == null: return
	var vs := get_viewport_rect().size
	if landscape:
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		var k := maxf(vs.x / t.get_width(), vs.y / t.get_height())
		backdrop.set_anchors_preset(Control.PRESET_TOP_LEFT)
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.position = Vector2((vs.x - t.get_width() * k) / 2.0, 0.0)
		backdrop.size = Vector2(t.get_width(), t.get_height()) * k

# ------------------------------------------------------------------ input
func _can_edit() -> bool:
	return not won and not card_open and screen == "board" and not too_small

## CSS px per logical px (viewport stretch / devicePixelRatio).
func css_scale() -> float:
	var sc := get_viewport().get_final_transform().get_scale().x
	if OS.has_feature("web"):
		var dpr = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		return sc / float(dpr if dpr != null else 1.0)
	return sc

## TT-AC-48: the board's cell would be < 44 CSS px -> cover it with the message, input blocked, state kept.
func _check_too_small() -> void:
	var cell_css: float = board.cell_size() * css_scale()
	var ts := screen == "board" and board.size.x > 0.0 and cell_css < 44.0 - 0.01
	if ts == too_small: return
	too_small = ts
	too_small_cover.visible = ts
	Dbg.hit("too_small %s (cell %.1f css px)" % [ts, cell_css])
	_sync_hint_button()

func _input_happened() -> void:
	idle_s = 0.0
	if hint_state.text != "" and str(puzzle.get("coach", "")) == "":
		hint_state.text = ""; hint_label.text = Cfg.RULES_TEXT; board.hint_target = {}; board.hint_unit = {}
	last_hint_step = {}; if showme_btn: showme_btn.visible = false

func _push_history() -> void:
	history.append(board.cells.duplicate())
	if history.size() > 200: history.pop_front()

## One tap: empty -> mold -> cake -> empty, or with Settings "Tap order: cake first" empty -> cake -> mold -> empty (D-12).
## Given (plated) cakes never change (TT-AC-24).
func tap_cell(r: int, c: int) -> void:
	if not _can_edit(): return
	var i := r * n + c
	if givens.has(i): return
	_push_history()
	var before: int = board.cells[i]
	board.cells[i] = Cells.next_state(before, settings.tap_order)
	board.notify_change(i, before, board.cells[i])
	moves += 1
	_input_happened()
	_refresh()
	_schedule_save()

## Desktop right-click: toggles the empty mold (empty <-> mold), never a cake (D-12).
func right_click_cell(r: int, c: int) -> void:
	if not _can_edit(): return
	var i := r * n + c
	if givens.has(i): return
	_push_history()
	var before: int = board.cells[i]
	board.cells[i] = Cells.right_click(before)
	board.notify_change(i, before, board.cells[i])
	moves += 1
	_input_happened()
	_refresh()
	_schedule_save()

## Undo the last tap / right-click / reset on this board; blocked after solve (R6).
func undo() -> void:
	if history.is_empty() or not _can_edit(): return
	board.cells = history.pop_back(); undo_count += 1
	if chapter > 0 and mode == "chapter": progress.stats(chapter).undo_count += 1
	_input_happened(); _refresh(); _schedule_save()

func request_reset() -> void:
	if _can_edit(): reset_modal.visible = true

## Reset: empties every non-given cell (one undo step).
func clear_board() -> void:
	if won and card_open: return
	_push_history()
	for i in n * n:
		if not givens.has(i): board.cells[i] = Cells.EMPTY
	moves = 0; won = false; _refresh(); _schedule_save()

func set_tap_order(order: String) -> void:
	settings.tap_order = order; save_now("settings"); _sync_setting_buttons(); _refresh()

func set_auto_mold(on: bool) -> void:
	settings.auto_mold = on; save_now("settings"); _sync_setting_buttons(); _refresh()

func set_sound(on: bool) -> void:
	settings.sound = on; muted = not on; Sfx.set_user_muted(not on); save_now("settings"); _sync_setting_buttons()

func set_music(on: bool) -> void:
	settings.music = on; Sfx.set_music(on); save_now("settings"); _sync_setting_buttons()

## Settings "Reset progress" after its confirm: progress + daily history cleared under the fixed save key; settings kept.
## Routes to the first tray (c1-b1, tutorial) like a first boot.
func reset_progress() -> void:
	progress_reset_modal.visible = false; settings_modal.visible = false
	if card_open: _close_card()
	progress = Progress.new(); daily = Daily.new()
	ad_policy.chapters_completed = 0
	mode = "chapter"; chapter = 0
	save_now("reset_progress")
	Dbg.hit("reset progress")
	_mark_transition_start()
	open_board("c1-b1")

func _sync_setting_buttons() -> void:
	if order_btn == null: return
	var cf: bool = settings.tap_order == Cells.ORDER_CAKE_FIRST
	order_btn.set_pressed_no_signal(cf); order_btn.icon = TtTheme.ui_tex("toggle_on" if cf else "toggle_off")
	automold_btn.set_pressed_no_signal(settings.auto_mold)
	automold_btn.icon = TtTheme.ui_tex("toggle_on" if settings.auto_mold else "toggle_off")
	mute.set_pressed_no_signal(not muted); mute.icon = TtTheme.ui_tex("toggle_off" if muted else "toggle_on")
	music_btn.set_pressed_no_signal(settings.music); music_btn.icon = TtTheme.ui_tex("toggle_on" if settings.music else "toggle_off")

func set_cell(r: int, c: int, v: int) -> void:
	board.cells[r * n + c] = v; _refresh()

## All cakes on the board (givens included), as Vector2i.
func all_cakes() -> Array:
	var out := []
	for i in n * n:
		if board.cells[i] == Cells.CAKE: out.append(Vector2i(i / n, i % n))
	return out

## Player cakes (givens excluded).
func cakes() -> Array:
	return all_cakes().filter(func(p): return not givens.has(p.x * n + p.y))

func player_molds() -> Array:
	var out := []
	for i in n * n:
		if board.cells[i] == Cells.MOLD: out.append(Vector2i(i / n, i % n))
	return out

func _refresh() -> void:
	var cs := all_cakes()
	var bad := Rules.conflicts(n, puzzle.regions, cs)
	var before: int = board.conflict_cells.size()
	board.set_conflicts(bad)
	if bad.size() > before:
		conflicts_board += 1
		if chapter > 0 and mode == "chapter": progress.stats(chapter).conflicts_shown += 1
	board.conflict_units = BoardView.units_of_conflicts(n, puzzle.regions, bad)
	board.auto = Cells.auto_molds(n, puzzle.regions, board.cells, settings.auto_mold)
	var was_won := won
	won = Rules.is_solution(n, puzzle.regions, cs)
	board.won = won
	board.queue_redraw()
	if undo_btn: undo_btn.disabled = history.is_empty() or won
	if reset_btn: reset_btn.disabled = won
	if won:
		status.text = "Tray baked! Golden and perfect."
		if not was_won: _on_solved()
	elif not bad.is_empty():
		status.text = "Those cakes would stick together in the oven."
	else:
		status.text = "%d of %d cakes placed." % [cs.size(), n]
	_sync_hint_button()

# ------------------------------------------------------------------ solve flow
func _on_solved() -> void:
	interactive = false
	t_solved_ms = Time.get_ticks_msec()
	var id := board_id()
	Dbg.hit("WIN %s n=%d seed=%d moves=%d" % [id, n, seed_value, moves])
	board.hint_target = {}; board.hint_unit = {}
	var first := false
	if mode == "chapter" or mode == "replay": first = progress.mark_solved(id)
	last_stars = Progress.stars_for(hints_used_board, conflicts_board)
	if mode == "chapter" or mode == "replay": progress.record_stars(id, last_stars)
	if chapter > 0 and mode == "chapter": progress.stats(chapter).active_s += active_ms / 1000.0
	Analytics.board_complete(id, "daily" if mode == "daily" else "chapter", n, int(puzzle.get("grade", 0)),
		active_ms / 1000.0, hints_used_board, undo_count, mode == "replay")
	if mode == "daily" and daily.open_date != "":
		var r := complete_daily()
		status.text = "Bake of the Day done! Streak: %d" % r.streak + ("\nA fresh streak starts today." if r.fresh_line else "")
	save_now("solve")
	board.start_bake(seed_value)
	if intro_done: Ads.set_context("results")            # solved card: gameplayStop
	var s := int(active_ms / 1000.0)
	card_time.text = "Baked in %d:%02d" % [s / 60, s % 60]   # D-16: time only on the solved card
	card_stars.visible = mode != "free"; card_stars.filled = last_stars
	card_tip.visible = mode != "free" and last_stars < 3
	card_tip.text = "No hints for 2 stars, and no clashes too for 3." if last_stars == 1 else "Bake it with no clashes for 3 stars."
	card_open = true; solved_card.visible = true; card_open_ms = Time.get_ticks_msec()
	_card_first = first
	card_timer.start()

var _card_first := false
var card_open_ms := 0
var t_solved_ms := 0           # engine ticks at solve (TT-AC-25 timing, debug dump)
var t_interactive_ms := 0      # engine ticks when the current board became interactive

## Tap skips the card; the solving tap's own emulated mouse/touch twin (same input, < 250 ms) must not skip it.
func _on_card_input(ev: InputEvent) -> void:
	var down: bool = (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed)
	if down and Time.get_ticks_msec() - card_open_ms >= 250: _after_card()

func _close_card() -> void:
	card_timer.stop(); card_open = false; solved_card.visible = false

## After the bake reward + "Baked!" card (auto at 1.5 s, or one tap): next board / chapter end / Home (TT-AC-25).
func _after_card() -> void:
	if not card_open: return
	_close_card()
	if mode == "daily": show_home(); return
	if mode == "free": board.stop_bake(); if intro_done: Ads.set_context("play"); return
	if board_no < Chapters.BOARDS:
		_mark_transition_start()
		open_board("c%d-b%d" % [chapter, board_no + 1])
	elif mode == "chapter" or (_card_first and progress.chapter_done(chapter) and not (chapter in progress.recipes)):
		show_chapter_end(chapter)
	elif progress.chapter_done(chapter) and not (chapter in progress.recipes):
		show_chapter_end(chapter)
	else:
		show_home()

## First completion of a chapter: recipe card + décor (TT-AC-26), chapter_complete hook, happytime (§12.1).
func show_chapter_end(ch: int) -> void:
	last_chapter_end = ch
	var first: bool = progress.unlock_chapter(ch)
	ad_policy.on_chapter_completed(ch)
	if first:
		var st: Dictionary = progress.stats(ch)
		Analytics.chapter_complete({"chapter_id": ch, "board_size": _max_size_in(ch), "hints_used": st.hints_used,
			"hints_free": st.hints_free, "hints_rewarded": st.hints_rewarded, "duration_s": st.active_s,
			"wall_s": int(Time.get_unix_time_from_system()) - int(st.t0_unix), "sessions": st.sessions,
			"undo_count": st.undo_count, "conflicts_shown": st.conflicts_shown})
		Ads.sdk("happytime", "window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game && window.CrazyGames.SDK.game.happytime()")
	progress.current_id = ""; progress.current_cells = []
	save_now("chapter_end")
	end_title.text = "Chapter %d baked!" % ch
	end_card.chapter = ch; end_card.unlocked = true; end_card.refresh()
	end_decor.text = "New for your tea room: %s." % Chapters.DECOR[ch - 1]
	end_shelf.set_owned(progress.decor)
	end_next.visible = Chapters.available(ch + 1)
	set_screen("chapter_end")
	end_card.flip_in.call_deferred()
	end_shelf.drop(ch)

func _max_size_in(ch: int) -> int:
	var m := 0
	for b in range(1, Chapters.BOARDS + 1): m = maxi(m, int(Chapters.board(ch, b).get("n", 0)))
	return m

## Chapter-end screen -> "Next chapter" / "Home": the ONLY midgame slot (D-19). Every decision is logged (BR-3).
var _end_busy := false
func chapter_end_continue(dest: String) -> void:
	if _end_busy: return
	_end_busy = true
	var e := chapter_end_slot(last_chapter_end)
	if e.allowed: await Ads.midgame("chapter_end")
	_end_busy = false
	if dest == "next" and Chapters.available(last_chapter_end + 1): open_board("c%d-b1" % (last_chapter_end + 1))
	elif progress.all_done() and not progress.all_baked_seen: show_all_baked()
	else: show_home()

## §7.2 "All recipes baked" (once, after the ch8 chapter end): 8-card spread + full shelf + one line + "Home".
func show_all_baked() -> void:
	progress.all_baked_seen = true
	save_now("all_baked")
	all_shelf.set_owned(progress.decor)
	set_screen("all_baked")

## Level map (SPEC v1.1 §9): best stars per level, solved levels replayable, the next level playable, later ones locked.
func show_level_map() -> void:
	var nxt: String = progress.next_unsolved()
	for ch in range(1, Chapters.count_available() + 1):
		var got := 0
		for b in range(1, Chapters.BOARDS + 1):
			var id := "c%d-b%d" % [ch, b]
			var bb: Button = map_buttons[id]
			var st: int = progress.stars_of(id)
			got += st
			bb.disabled = not progress.level_open(id)
			bb.theme_type_variation = "PrimaryButton" if id == nxt else ""
			bb.icon = TtTheme.icon("lock") if bb.disabled else null
			bb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER; bb.expand_icon = false
			var num: Label = bb.find_child("Num", true, false)
			num.visible = not bb.disabled
			num.add_theme_color_override("font_color", Pal.CLOTTED_CREAM if id == nxt else Pal.EARL_GREY_INK)
			var sr = bb.find_child("Stars", true, false)
			sr.filled = st; sr.visible = st > 0
		(map_box.get_node("MapHead%d/MapCh%d" % [ch, ch]) as Label).text = "Chapter %d · %s · %d/%d stars" % [ch, Chapters.RECIPES[ch - 1], got, Chapters.BOARDS * 3]
	map_total.text = "%d/%d" % [progress.total_stars(), Progress.max_stars()]
	set_screen("level_map")
	_scroll_map_to.call_deferred(nxt)

func _scroll_map_to(id: String) -> void:
	if id == "" or not map_buttons.has(id): return
	await get_tree().process_frame
	var head: Control = map_box.get_node("MapHead%d" % Chapters.parse_id(id)[0])   # chapter heading of the next level
	map_scroll.scroll_vertical = int(maxf(0.0, head.get_global_rect().position.y - map_box.get_global_rect().position.y - 8.0))

## Level map tap: replay a solved level, play the next one; locked levels do nothing.
func open_level(id: String) -> bool:
	if progress.is_solved(id): return replay_board(id)
	if not progress.level_open(id): return false
	_mark_transition_start()
	return open_board(id, true)

## Compatibility alias (QA hook "chapter_list" / old callers): the level map replaced the "Replay a chapter" list.
func show_chapter_list() -> void:
	show_level_map()

## Replay one solved board: mode "replay" (no unlocks, no chapter events, no midgame; hints follow the board).
func replay_board(id: String) -> bool:
	if not progress.is_solved(id): return false
	_mark_transition_start()
	return open_board(id)

## Midgame decision at the chapter-end slot: every decision (allowed or denied, SPEC §13.1 BR-3 reason codes) is
## emitted on Ads.decided (debug hooks record it in dump().ads_decisions[]). Returns the decision; the caller requests.
func chapter_end_slot(ch: int) -> Dictionary:
	var m := mode if mode in ["daily", "replay"] else "chapter"
	var e: Dictionary = ad_policy.decide(ch, Clock.session_ms(), Ads.available(), "chapter_end", m, Clock.session_started())
	Ads.decided.emit(e)
	return e

# ------------------------------------------------------------------ hints (§6, §3.4, D-07, D-19)
func _hint_chapter() -> int:
	return chapter if chapter > 0 else (2 if mode == "daily" else 1)

func _sync_hint_button() -> void:
	if hint_btn == null: return
	var offer: String = ad_policy.hint_offer(_hint_chapter(), "daily" if mode == "daily" else "chapter", Ads.available())
	var ch1_free: bool = _hint_chapter() <= 1 and mode != "daily"
	hint_state.free_left = -1 if ch1_free else maxi(0, Cfg.HINTS_FREE_PER_BOARD - ad_policy.free_hints_used_this_board)
	hint_state.rewarded_visible = offer == "rewarded"
	hint_btn.disabled = offer == "none" or won or not interactive or too_small
	hint_badge.visible = offer == "rewarded" or (offer == "free" and not ch1_free)
	hint_badge.texture = TtTheme.ui_tex("badge_rewarded" if offer == "rewarded" else "badge_free_hint")

func request_hint() -> void:
	if not _can_edit(): return
	var offer: String = ad_policy.hint_offer(_hint_chapter(), "daily" if mode == "daily" else "chapter", Ads.available())
	idle_s = 0.0
	if offer == "free": show_hint("free")
	elif offer == "rewarded": reward_modal.visible = true

func _watch_for_hint() -> void:
	reward_modal.visible = false
	Ads.set_context("play_panel")          # gameplayStop for the ad
	var ok: bool = await Ads.rewarded("hint")
	if screen == "board" and not won: Ads.set_context("play")
	if ok: show_hint("rewarded")            # granted only on ad success (TT-AC-11)
	_sync_hint_button()

## Next deduction from the player's own state (fix-first), as plain words + gold unit glow + pulsing target.
func show_hint(kind: String) -> Dictionary:
	var step: Dictionary = Grader.next_hint(n, puzzle.regions, puzzle.solution, all_cakes(), player_molds())
	if step.is_empty(): return {}
	ad_policy.on_hint_used(kind)
	hints_used_board += 1
	if chapter > 0 and mode == "chapter":
		var st: Dictionary = progress.stats(chapter); st.hints_used += 1
		if kind == "rewarded": st.hints_rewarded += 1
		else: st.hints_free += 1
	var tgt: Array = step.get("cells", []) if step.get("place", false) or step.technique == "fix" else step.get("eliminations", [])
	board.hint_target = {}; board.hint_unit = {}
	for i in tgt: board.hint_target[i] = true
	for i in _unit_cells(str(step.get("unit", ""))): board.hint_unit[i] = true
	var text := HintText.text(step)
	hint_state.text = text; hint_state.technique = step.technique; hint_state.kind = kind
	hint_state.targets = tgt.map(func(i): return [i / n, i % n])
	hint_label.text = text
	last_hint_step = step
	showme_btn.visible = not (step.technique == "contradiction")
	Analytics.hint_used(board_id(), kind, step.technique)
	Dbg.hit("hint %s %s: %s" % [kind, step.technique, text])
	_sync_hint_button()
	return step

## "Show me" (D-07 / HN-20): applies the shown hint as one undoable move: fix -> lift the wrong cake/mold; a placement
## -> plate the cake; eliminations -> empty molds on those cells. Returns false when there is no pending hint.
func apply_hint() -> bool:
	if last_hint_step.is_empty() or not _can_edit(): return false
	var st := last_hint_step
	_push_history()
	if st.technique == "fix":
		for i in st.cells: if not givens.has(i): board.cells[i] = Cells.EMPTY
	elif st.get("place", false):
		board.cells[int(st.cells[0])] = Cells.CAKE
	else:
		for i in st.get("eliminations", []):
			if not givens.has(i) and board.cells[i] == Cells.EMPTY: board.cells[i] = Cells.MOLD
	moves += 1
	Dbg.hit("show me %s" % st.technique)
	last_hint_step = {}; showme_btn.visible = false
	hint_state.text = ""; board.hint_target = {}; board.hint_unit = {}
	if str(puzzle.get("coach", "")) == "": hint_label.text = Cfg.RULES_TEXT
	_refresh(); _schedule_save()
	return true

func _unit_cells(lbl: String) -> Array:
	for u in Grader.units(n, puzzle.regions):
		if Grader.unit_label(u) == lbl: return u.cells
	return []

func _process(dt: float) -> void:
	if screen == "board" and interactive and not won and not page_hidden and not Ads.busy:
		active_ms += dt * 1000.0
		idle_s += dt
		if idle_s >= IDLE_PULSE_S and hint_state.pulse_count == 0 and not hint_btn.disabled:
			hint_state.pulse_count = 1                     # TT-AC-47: once per board, no hint consumed
			hint_btn.pivot_offset = hint_btn.size / 2.0
			var tw := create_tween(); tw.tween_property(hint_btn, "scale", Vector2(1.12, 1.12), 0.25); tw.tween_property(hint_btn, "scale", Vector2.ONE, 0.25)
			Dbg.hit("hint pulse")

# ------------------------------------------------------------------ save
func _schedule_save() -> void:
	if save_timer: save_timer.start()   # debounce: 1.0 s after the LAST change

## Writes now (solve, chapter end, settings, hidden, pagehide, home).
func save_now(reason: String) -> void:
	if save_timer: save_timer.stop()
	if mode == "chapter" and chapter > 0 and board.cells.size() == n * n and not won:   # (boot-to-Home: no board yet)
		progress.current_id = board_id()
		var cc := []
		for i in n * n: cc.append(0 if givens.has(i) else int(board.cells[i]))
		progress.current_cells = cc
	save_data["settings"] = settings.to_dict()
	save_data["daily"] = daily.to_dict()
	save_data["progress"] = progress.to_dict()
	save_data["chapters_completed"] = progress.chapters_completed
	Store.save(save_data, reason)

## visibilitychange -> hidden / pagehide: immediate save, gameplayStop; back to visible: gameplayStart if playing.
func _bind_page_events() -> void:
	if not OS.has_feature("web"): return
	var vis := JavaScriptBridge.create_callback(func(_a): _on_page_visibility())
	var hide := JavaScriptBridge.create_callback(func(_a): save_now("pagehide"))
	_js_cbs = [vis, hide]
	JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", vis)
	JavaScriptBridge.get_interface("window").addEventListener("pagehide", hide)

var _resume_play := false
func _on_page_visibility() -> void:
	page_hidden = str(JavaScriptBridge.eval("document.hidden ? 'y' : 'n'")) == "y"
	if page_hidden:
		save_now("hidden")
		_resume_play = Ads.context == "play"
		if intro_done and _resume_play: Ads.set_context("paused")
	elif _resume_play and intro_done:
		_resume_play = false
		Ads.set_context("play")

# ------------------------------------------------------------------ intro / lifecycle
func _preset_state(st: String) -> void:
	var sol: PackedInt32Array = puzzle.solution
	match st:
		"solved":
			for r in n: board.cells[r * n + sol[r]] = Cells.CAKE
		"almost":
			for r in n - 1: board.cells[r * n + sol[r]] = Cells.CAKE
		"conflict":
			board.cells[0] = Cells.CAKE; board.cells[n + 1] = Cells.CAKE
	_refresh()

func _on_intro_finished() -> void:
	intro_done = true
	Ads.hold(false)
	Store.loading_stop()      # CrazyGames loadingStop: intro finished AND scene ready
	Dbg.hit("intro finished")
	_gameplay_start()
	print("[PKD] intro finished")
	if screen == "board":
		_mark_transition_start()
		_board_interactive.call_deferred()
	else:
		Ads.set_context("menu")

## CrazyGames SDK v3 gameplayStart, once, when the first board is playable (U2 session starts here).
func _gameplay_start() -> void:
	if gameplay_started: return
	gameplay_started = true
	Clock.start_session()
	Ads.set_context("play" if screen == "board" else "menu")
	Dbg.hit("gameplayStart (%s)" % ("board 1" if screen == "board" else screen))

## BR-1 (§13.1; release + debug): performance.mark() + one "pkd:perf <mark> <ms>" console line per mark.
const PERF_JS := "(function(m,d){performance.mark(m,d?{detail:d}:undefined);console.log('pkd:perf '+m+' '+performance.now().toFixed(1));})(%s,%s)"
var _transition_open := false
var perf_marks: Array = []

func perf_mark(m: String, detail: Dictionary = {}) -> void:
	perf_marks.append({"mark": m, "board_id": detail.get("board_id", "")})
	if OS.has_feature("web"):
		JavaScriptBridge.eval(PERF_JS % [JSON.stringify(m), JSON.stringify(detail) if not detail.is_empty() else "null"])
	else:
		print("pkd:perf %s %.1f" % [m, Time.get_ticks_usec() / 1000.0])

func _mark_transition_start() -> void:
	if _transition_open: return
	_transition_open = true
	perf_mark("pkd:transition_start")

func _board_interactive() -> void:
	await get_tree().process_frame
	if screen != "board": return
	interactive = not won
	if interactive: t_interactive_ms = Time.get_ticks_msec()
	if intro_done and gameplay_started and not won and not settings_modal.visible: Ads.set_context("play")
	_sync_hint_button()
	if not _transition_open: return
	_transition_open = false
	var id := board_id()
	perf_mark("pkd:transition_end", {"board_id": id})
	perf_mark("pkd:board_interactive", {"board_id": id})
	board_t0_ms = Time.get_ticks_msec()
	var md := "daily" if mode == "daily" else "chapter"
	Analytics.board_start(id, md, n, int(puzzle.get("grade", 0)), mode == "replay")   # no-op sink (§12.4)
	if mode == "chapter" and board_no == 1 and not progress.chapter_stats.has(str(chapter)):
		progress.stats(chapter)
		Analytics.chapter_start(chapter, n, Chapters.BOARDS, progress.chapters_completed)

## Local-date change (a real midnight rollover, or the debug date hook): the open daily keeps its board date (U1/V9).
var current_date := ""
func check_day() -> void:
	var d := Clock.local_date()
	if current_date == "": current_date = d; return
	if d == current_date: return
	var old := current_date; current_date = d
	Dbg.hit("day change %s -> %s (open daily stays %s)" % [old, d, daily.open_date])
	if screen == "home": _refresh_home()

## Second completion attempt on today's daily: always rejected if already baked; streak/total unchanged (V8).
func retry_today_daily() -> Dictionary:
	return complete_daily(Clock.local_date())

## Cake piece for the current board (SPEC v1.2): chapter cake, chocolate on the daily, berry on debug boards.
func board_cake() -> String:
	if mode == "daily": return Chapters.DAILY_CAKE
	return Chapters.cake_for(chapter) if chapter > 0 else Chapters.DEFAULT_CAKE

func board_id() -> String:
	if mode == "daily": return "d-" + (daily.open_date if daily.open_date != "" else "done")
	if chapter > 0: return "c%d-b%d" % [chapter, board_no]
	return "gen-%d-%d" % [n, seed_value]

func preset(st: String) -> void:
	_preset_state(st)

func fresh_seed() -> int:
	return _fresh_seed()
