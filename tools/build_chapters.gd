## Builds res://game/levels/chapter_01.json + chapter_02.json (thin slice) from the validated packs (SPEC §3.2/§3.5
## sizes + grades, §6 tutorial, §16.1 format). godot --headless --path . -s tools/build_chapters.gd
## Tutorial trays c1-b1..b3 = G1 5x5 pack boards with hand-rule "givens" (plated cakes) chosen by search:
##  b1 rows & columns: 4 givens, the empty row/column leaves one cell -> 1 placement.
##  b2 colors: 3 givens; in an empty row exactly 2 cells survive row/column logic, both untouched by a given, and only
##     one lies in a color that still needs a cake -> 2 placements.
##  b3 no touching: 3 givens; an empty row has 2 row/column-free cells in colors without a given, one of them touches
##     a given diagonally -> mold it, place the other -> 2 placements.
## Every board is re-verified by tests/test_chapters.gd (unique, grade, sizes, givens on the solution, distinct).
extends SceneTree

const Solver = preload("res://game/solver.gd")
const Grader = preload("res://game/grader.gd")
const Packs = preload("res://tools/build_packs.gd")

const CH := {1: {"sizes": [5, 5, 5, 5, 5], "grades": [1, 1, 1, 1, 2]}, 2: {"sizes": [5, 6, 5, 6, 6], "grades": [2, 2, 1, 2, 2]}}
const COACH := [
	"Every row and column needs one cake. Tap the glowing cell twice to bake it.",
	"Each color needs one cake too. Pick the free cell whose color has no cake yet.",
	"Cakes can't touch, not even corners. Set an empty mold where it would touch, then bake the other cell."]

var used := {}

func load_pack(n: int, g: int) -> Array:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://game/levels/pack_%d_g%d.json" % [n, g]))
	var out := []
	for e in d.boards:
		var reg := PackedInt32Array()
		for row in e.regions:
			for ch in row: reg.append(ch.unicode_at(0) - 97)
		var sol := PackedInt32Array(); for v in e.solution: sol.append(int(v))
		out.append({"e": e, "n": n, "reg": reg, "sol": sol})
	return out

func touches(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1

## Free cells of row r after the givens' row/column eliminations only.
func rc_free(n: int, giv: Array, r: int) -> Array:
	var cols := {}
	for g in giv: cols[g.y] = true
	var out := []
	for c in n: if not cols.has(c): out.append(Vector2i(r, c))
	return out

func tut(b: Dictionary, kind: int) -> Dictionary:
	var n: int = b.n; var sol: PackedInt32Array = b.sol; var reg: PackedInt32Array = b.reg
	var all := []
	for r in n: all.append(Vector2i(r, sol[r]))
	if kind == 1:
		for drop in n:
			var giv := all.filter(func(p): return p.x != drop)
			return {"givens": giv, "targets": [all[drop]]}
	for d1 in n:
		for d2 in range(d1 + 1, n):
			var giv := all.filter(func(p): return p.x != d1 and p.x != d2)
			var given_regs := {}
			for g in giv: given_regs[reg[g.x * n + g.y]] = true
			for r in [d1, d2]:
				var f := rc_free(n, giv, r)
				if f.size() != 2: continue
				var touch := f.map(func(p): return giv.any(func(g): return touches(p, g)))
				var free_reg := f.map(func(p): return not given_regs.has(reg[p.x * n + p.y]))
				var sol_cell: Vector2i = all[r]
				if kind == 2 and touch == [false, false] and free_reg.count(true) == 1 and free_reg[f.find(sol_cell)]:
					return {"givens": giv, "targets": [sol_cell]}
				if kind == 3 and free_reg == [true, true] and touch.count(true) == 1 and not touch[f.find(sol_cell)] and f.has(sol_cell):
					return {"givens": giv, "targets": [sol_cell]}
	return {}

func entry(ch: int, k: int, b: Dictionary, extra: Dictionary) -> Dictionary:
	var n: int = b.n
	var rows := []
	for r in n:
		var s := ""
		for c in n: s += char(65 + b.reg[r * n + c])
		rows.append(s)
	var g = Grader.grade(n, b.reg)
	var e := {"id": "c%d-b%d" % [ch, k], "size": n, "regions": rows, "solution": Array(b.sol), "grade": int(g.grade),
		"techniques": g.techniques, "steps": g.steps.size(), "seed": int(b.e.seed), "gen": str(b.e.get("gen", "ttgen-0.2")),
		"source": str(b.e.id), "givens": []}
	for key in extra: e[key] = extra[key]
	e.givens = e.givens.map(func(p): return [p.x, p.y]) if not e.givens.is_empty() and e.givens[0] is Vector2i else e.givens
	if e.has("targets"): e.targets = e.targets.map(func(p): return [p.x, p.y])
	return e

func pick(n: int, g: int, pred := Callable()) -> Dictionary:
	for b in load_pack(n, g):
		var key := Packs.canon(n, b.reg)
		if used.has(key): continue
		if Solver.new().count(n, b.reg, 2) != 1: continue
		if pred.is_valid() and pred.call(b).is_empty(): continue
		used[key] = true
		return b
	push_error("no board for %dx%d g%d" % [n, g]); quit(1); return {}

func _init() -> void:
	for ch in CH:
		var boards := []
		for k in 5:
			var n: int = CH[ch].sizes[k]; var gr: int = CH[ch].grades[k]
			if ch == 1 and k < 3:
				var kind := k + 1
				var b := pick(n, gr, func(bb): return tut(bb, kind))
				var t := tut(b, kind)
				t["coach"] = COACH[k]
				boards.append(entry(ch, k + 1, b, t))
			else:
				boards.append(entry(ch, k + 1, pick(n, gr), {}))
		var doc := {"chapter": ch, "format": "tt-chapter-1", "spec": "SPEC v1.0.1 §3.5", "boards": boards}
		var f := FileAccess.open("res://game/levels/chapter_%02d.json" % ch, FileAccess.WRITE)
		f.store_string(JSON.stringify(doc, " ", false)); f.close()
		print("chapter %d: %s" % [ch, ", ".join(boards.map(func(e): return "%s %dx%d g%d (%s)" % [e.id, e.size, e.size, e.grade, e.source]))])
	quit(0)
