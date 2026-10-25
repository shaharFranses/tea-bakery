## Responsive layout rules (pure logic; tests/test_ui_layout.gd). Pattern: sudoku-dash dev a795a1a game/ui_layout.gd,
## adapted for a portrait-first game. Stretch stays canvas_items + aspect "expand" (project.godot); main.gd sets
## Window.content_scale_size = logical_size(css) on every size_changed, so:
##   * one logical unit is NEVER smaller than one CSS px (units_per_css <= 1): a 44-unit button is >= 44 CSS px and a
##     12-unit font is >= 12 CSS px at any page size (the starter's fixed 390x844 base shrank both at 800x450);
##   * big pages scale UP (tablet portrait wider than PORTRAIT_MAX_W, desktops taller than WIDE_MAX_H).
## Modes (breakpoint WIDE_ASPECT on the CSS aspect w/h):
##   "portrait" (aspect <= 1.0): one column: title, rules, sizes, board, status, buttons (390x844 base look).
##   "wide"     (aspect  > 1.0): board fills the height on the left, card + buttons in a side panel on the right
##                               (Art mock art/mocks/desktop_wide_9x9_800x450.png). CrazyGames embed 800x450 = 1:1.
extends RefCounted

const WIDE_ASPECT := 1.0          # CSS w/h above this -> "wide" (board left, panel right)
const PORTRAIT_MAX_W := 480.0     # portrait pages wider than this scale up (logical width stays 480)
const WIDE_MAX_H := 720.0         # wide pages taller than this scale up (logical height stays 720)
const MIN_TOUCH := 44.0           # logical units == CSS px floor (units_per_css <= 1)
const MIN_FONT := 12.0
const MARGIN := 12.0
const PANEL_MIN_W := 280.0
const PANEL_MAX_W := 360.0
const GAP := 12.0

static func mode(css: Vector2) -> String:
	if css.x <= 0.0 or css.y <= 0.0: return "portrait"
	return "wide" if css.x / css.y > WIDE_ASPECT else "portrait"

## Logical viewport (content_scale_size) for a page of `css` CSS px. Never larger than css (units >= 1 CSS px).
static func logical_size(css: Vector2) -> Vector2:
	if css.x <= 0.0 or css.y <= 0.0: return Vector2(390, 844)
	var k := 1.0
	if mode(css) == "wide": k = maxf(1.0, css.y / WIDE_MAX_H)
	else: k = maxf(1.0, css.x / PORTRAIT_MAX_W)
	return (css / k).floor()

## CSS px per logical unit (>= 1).
static func css_per_unit(css: Vector2) -> float:
	var ls := logical_size(css)
	return css.x / ls.x if ls.x > 0.0 else 1.0

## Wide mode split of a logical viewport: {board: Rect2, panel: Rect2}. Board is a square filling the height; the
## panel takes the rest (clamped), the pair centred horizontally.
static func wide_split(vp: Vector2, insets := [0.0, 0.0, 0.0, 0.0]) -> Dictionary:
	var top: float = MARGIN + insets[0]; var right: float = MARGIN + insets[1]
	var bottom: float = MARGIN + insets[2]; var left: float = MARGIN + insets[3]
	var h := vp.y - top - bottom
	var avail_w := vp.x - left - right
	var side := minf(h, avail_w - GAP - PANEL_MIN_W)
	var panel_w := clampf(avail_w - GAP - side, PANEL_MIN_W, PANEL_MAX_W)
	var total := side + GAP + panel_w
	var x0 := left + maxf(0.0, (avail_w - total) / 2.0)
	return {"board": Rect2(x0, top + (h - side) / 2.0, side, side), "panel": Rect2(x0 + side + GAP, top, panel_w, h)}
