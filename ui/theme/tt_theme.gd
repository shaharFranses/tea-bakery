## Runtime Theme from Art's P1 UI kit (art/HANDOFF_GODOT.md P1, docs/art/STYLE_GUIDE.md). @2x textures only;
## 9-slices via Slice2x (margins at 1x). Fonts: Lexend (UI, FontVariation wght 400/600), DM Serif Display (headings).
## Button variations: "PrimaryButton" (raspberry), "SecondaryButton" (sage), default Button = tool (cream, ink outline:
## Undo / Hint / Reset, toggles). "RoundButton" = 56x56 top-bar icon button. Panels: "CardPanel", "ModalPanel",
## "CoachBubble" (rules / coach / hint bubble, 24 px stretch margins), "HoneyChip".
extends RefCounted

const Pal = preload("res://ui/theme/art_palette.gd")
const Slice = preload("res://ui/theme/slice2x.gd")
const UI := "res://assets/ui/"
const LEXEND := "res://assets/fonts/Lexend-VariableFont_wght.ttf"
const SERIF := "res://assets/fonts/DMSerifDisplay-Regular.ttf"
const BTN_M := Vector4(24, 24, 24, 24)
const BTN_PAD := Vector4(16, 8, 16, 8)
const BUBBLE_MIN_H := 72.0
const BUBBLE_3LINE_H := 88.0     # 3 x 20 px lines + 2 x 12 px padding (ruling 10:19)

static func lexend(weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load(LEXEND)
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f

static func serif() -> Font:
	return load(SERIF)

static func icon(name: String, cream := false) -> Texture2D:
	return load(UI + "icons/icon_%s%s@2x.png" % [name, "_cream" if cream else ""])

static func ui_tex(name: String) -> Texture2D:
	return load(UI + name + "@2x.png")

static func slice(name: String, m: Vector4, pad: Vector4) -> StyleBox:
	return Slice.make(UI + name + "@2x.png", m, pad)

static func _button_type(th: Theme, type: String, style: String, text_col: Color, base := "Button") -> void:
	if type != "Button": th.set_type_variation(type, base)
	th.set_stylebox("normal", type, slice("btn_%s_normal" % style, BTN_M, BTN_PAD))
	th.set_stylebox("hover", type, slice("btn_%s_normal" % style, BTN_M, BTN_PAD))
	th.set_stylebox("pressed", type, slice("btn_%s_pressed" % style, BTN_M, BTN_PAD))
	th.set_stylebox("hover_pressed", type, slice("btn_%s_pressed" % style, BTN_M, BTN_PAD))
	th.set_stylebox("disabled", type, slice("btn_%s_disabled" % style, BTN_M, BTN_PAD))
	th.set_stylebox("focus", type, StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		th.set_color(k, type, text_col)
	th.set_color("font_disabled_color", type, Color(text_col, 0.55))
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		th.set_color(k, type, Color.WHITE)
	th.set_constant("h_separation", type, 8)
	th.set_constant("icon_max_width", type, 28)

const SCROLLBAR_W := 14.0   # slim pill scrollbar: a soft plum track, a raspberry thumb with a cream rim

static func _pill(col: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new(); sb.bg_color = col
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(bw); sb.border_color = border
	sb.content_margin_left = SCROLLBAR_W / 2.0; sb.content_margin_right = SCROLLBAR_W / 2.0
	sb.content_margin_top = 12.0; sb.content_margin_bottom = 12.0
	return sb

static func _scrollbar(th: Theme) -> void:
	var track := _pill(Color(Pal.EARL_GREY_INK, 0.12), Color(Pal.CLOTTED_CREAM, 0.55), 2)
	var thumb := _pill(Pal.RASPBERRY_JAM, Pal.CLOTTED_CREAM, 2)
	var thumb_hi := _pill(Pal.RASPBERRY_JAM.lightened(0.12), Pal.CLOTTED_CREAM, 2)
	var thumb_pr := _pill(Pal.RASPBERRY_JAM.darkened(0.12), Pal.CLOTTED_CREAM, 2)
	for t in ["VScrollBar", "HScrollBar"]:
		th.set_stylebox("scroll", t, track); th.set_stylebox("scroll_focus", t, track)
		th.set_stylebox("grabber", t, thumb); th.set_stylebox("grabber_highlight", t, thumb_hi)
		th.set_stylebox("grabber_pressed", t, thumb_pr)
		for k in ["increment", "decrement", "increment_highlight", "decrement_highlight", "increment_pressed", "decrement_pressed"]:
			th.set_icon(k, t, ImageTexture.new())   # no arrow buttons
	th.set_constant("scrollbar_h_separation", "ScrollContainer", 6)
	th.set_constant("scrollbar_v_separation", "ScrollContainer", 6)

static func build() -> Theme:
	var th := Theme.new()
	var body := lexend(400); var strong := lexend(600)
	th.default_font = body
	th.default_font_size = 16
	th.set_color("font_color", "Label", Pal.EARL_GREY_INK)
	th.set_font("font", "Button", strong)
	th.set_font_size("font_size", "Button", 17)
	_button_type(th, "Button", "tool", Pal.EARL_GREY_INK)
	_button_type(th, "PrimaryButton", "primary", Pal.CLOTTED_CREAM)
	_button_type(th, "SecondaryButton", "secondary", Pal.CLOTTED_CREAM)
	th.set_type_variation("RoundButton", "Button")
	var rn := StyleBoxTexture.new(); rn.texture = ui_tex("btn_round_normal")
	var rp := StyleBoxTexture.new(); rp.texture = ui_tex("btn_round_pressed")
	for sb in [rn, rp]: sb.set_content_margin_all(12)   # 56 px button, 32 px icon centred
	th.set_stylebox("normal", "RoundButton", rn); th.set_stylebox("hover", "RoundButton", rn)
	th.set_stylebox("pressed", "RoundButton", rp); th.set_stylebox("hover_pressed", "RoundButton", rp)
	th.set_stylebox("focus", "RoundButton", StyleBoxEmpty.new())
	th.set_constant("icon_max_width", "RoundButton", 32)
	th.set_type_variation("TitleLabel", "Label")
	th.set_font("font", "TitleLabel", serif())
	th.set_font_size("font_size", "TitleLabel", 28)
	th.set_type_variation("CardPanel", "PanelContainer")
	th.set_stylebox("panel", "CardPanel", slice("panel_card", Vector4(32, 32, 32, 32), Vector4(20, 20, 20, 20)))
	th.set_type_variation("ModalPanel", "PanelContainer")
	th.set_stylebox("panel", "ModalPanel", slice("panel_modal", Vector4(32, 32, 32, 32), Vector4(20, 20, 20, 20)))
	th.set_type_variation("CoachBubble", "PanelContainer")
	th.set_stylebox("panel", "CoachBubble", slice("coach_bubble", Vector4(24, 24, 24, 24), Vector4(14, 12, 14, 12)))
	th.set_type_variation("HoneyChip", "PanelContainer")
	th.set_stylebox("panel", "HoneyChip", slice("chip_honey", Vector4(20, 18, 20, 18), Vector4(14, 6, 14, 6)))
	_scrollbar(th)
	th.set_type_variation("BubbleLabel", "Label")
	th.set_font_size("font_size", "BubbleLabel", 16)
	th.set_constant("line_spacing", "BubbleLabel", 0)
	return th
