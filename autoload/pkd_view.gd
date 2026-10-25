## Viewport helpers: safe-area insets (CSS env() via PKD_VIEW in html/head_include.html) in viewport px.
## Minimums from Playbook v1: 44 CSS px tap targets, 12 CSS px text (DL retro).
extends Node

signal insets_changed

const MIN_TAP_CSS := 44.0
const MIN_TEXT_CSS := 12.0
var insets_css := [0.0, 0.0, 0.0, 0.0]   # top, right, bottom, left (CSS px)

func _ready() -> void:
	get_viewport().size_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if OS.has_feature("web"):
		var s = JavaScriptBridge.eval("window.PKD_VIEW ? JSON.stringify(window.PKD_VIEW.insets()) : '[0,0,0,0]'")
		var a = JSON.parse_string(str(s))
		if a is Array and a.size() == 4: insets_css = a
	insets_changed.emit()

## CSS px -> viewport (canvas) px for the current stretch.
func css_to_px(css: float) -> float:
	var vp := get_viewport()
	var win := DisplayServer.window_get_size()
	var dpr := 1.0
	if OS.has_feature("web"):
		dpr = float(JavaScriptBridge.eval("window.devicePixelRatio || 1"))
	var scale := float(win.x) / maxf(1.0, vp.get_visible_rect().size.x)
	return css * dpr / maxf(0.001, scale)

## Safe-area margins in viewport px: [top, right, bottom, left].
func safe_margins() -> Array:
	return insets_css.map(func(v): return css_to_px(float(v)))

func min_tap_px() -> float: return css_to_px(MIN_TAP_CSS)
func min_text_px() -> float: return css_to_px(MIN_TEXT_CSS)
