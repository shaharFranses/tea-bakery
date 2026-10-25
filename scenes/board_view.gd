## Tea & Tarts board: draws the tray (dough patches, patch borders, X marks, cakes, conflict highlight)
## and turns taps into cell cycles: empty -> X mark -> cake -> empty. Code-drawn (no art yet; placeholder palette).
extends Control

signal cell_tapped(r: int, c: int)

const EMPTY := 0
const MARK := 1
const CAKE := 2
## Placeholder dough palette (pastel, distinct). ART owns the final palette + CVD check.
const PATCH_COLORS := [Color("f4d6a0"), Color("f2b8b5"), Color("c9e4c5"), Color("b8d8f0"), Color("e6cdf2"),
	Color("fbe7a1"), Color("f6c9a6"), Color("cfe8e2"), Color("dcd3c4")]
const INK := Color("4a3428")
const CONFLICT := Color("d1323b")

var n := 5
var regions := PackedInt32Array()
var cells := PackedInt32Array()    # EMPTY / MARK / CAKE per cell
var conflict_cells := {}            # Vector2i -> true
var won := false

func setup(size: int, reg: PackedInt32Array) -> void:
	n = size; regions = reg
	cells = PackedInt32Array(); cells.resize(n * n); cells.fill(EMPTY)
	conflict_cells = {}; won = false
	queue_redraw()

func board_rect() -> Rect2:
	var side: float = min(size.x, size.y)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))

func cell_size() -> float:
	return board_rect().size.x / max(n, 1)

func cell_at(local: Vector2) -> Vector2i:
	var br := board_rect()
	if not br.has_point(local): return Vector2i(-1, -1)
	var cs := cell_size()
	var c := clampi(int((local.x - br.position.x) / cs), 0, n - 1)
	var r := clampi(int((local.y - br.position.y) / cs), 0, n - 1)
	return Vector2i(r, c)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var rc := cell_at(e.position)
		if rc.x >= 0:
			accept_event()
			cell_tapped.emit(rc.x, rc.y)

func _draw() -> void:
	if regions.size() != n * n: return
	var br := board_rect(); var cs := cell_size()
	draw_rect(br.grow(4), INK)
	for i in n * n:
		var r := i / n; var c := i % n
		var rect := Rect2(br.position + Vector2(c * cs, r * cs), Vector2(cs, cs))
		var col: Color = PATCH_COLORS[regions[i] % PATCH_COLORS.size()]
		if won: col = col.lerp(Color("f7c948"), 0.35)
		draw_rect(rect, col)
		draw_rect(rect, INK.lerp(col, 0.75), false, 1.0)   # thin cell grid
		var ctr := rect.get_center()
		if cells[i] == MARK:
			var k := cs * 0.16
			draw_line(ctr - Vector2(k, k), ctr + Vector2(k, k), INK.lerp(col, 0.35), max(2.0, cs * 0.05))
			draw_line(ctr + Vector2(-k, k), ctr + Vector2(k, -k), INK.lerp(col, 0.35), max(2.0, cs * 0.05))
		elif cells[i] == CAKE:
			var bad := conflict_cells.has(Vector2i(r, c))
			if bad: draw_rect(rect.grow(-2), Color(CONFLICT, 0.35))
			# placeholder tart: crust ring, cream, cherry
			draw_circle(ctr, cs * 0.36, Color("b5651d"))
			draw_circle(ctr, cs * 0.28, Color("fff3e0"))
			draw_circle(ctr + Vector2(0, -cs * 0.04), cs * 0.09, CONFLICT if bad else Color("c2185b"))
			if bad: draw_rect(rect.grow(-2), CONFLICT, false, max(3.0, cs * 0.07))
	# thick borders between patches
	var w: float = max(3.0, cs * 0.08)
	for r in n:
		for c in n:
			var i := r * n + c
			var p := br.position + Vector2(c * cs, r * cs)
			if c < n - 1 and regions[i] != regions[i + 1]:
				draw_line(p + Vector2(cs, 0), p + Vector2(cs, cs), INK, w)
			if r < n - 1 and regions[i] != regions[i + n]:
				draw_line(p + Vector2(0, cs), p + Vector2(cs, cs), INK, w)
	draw_rect(br, INK, false, w)
