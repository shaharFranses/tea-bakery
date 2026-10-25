## tea-bakery human-style technique ladder (SPEC v0.2 §16.3), structured like sudoku-dash dev a795a1a sudoku/logic.gd:
## find_step() returns the EASIEST applicable step {technique, grade, place, cells, eliminations, unit, explanation};
## run()/grade() apply steps until solved; grade = hardest technique used; "T7" = needs guessing (reject for shipped boards).
## A board the ladder solves without T7 is unique by construction (the solver count stays as a cross-check).
## State: cand = PackedByteArray n*n (1 = still possible), cakes = PackedInt32Array col per row (-1 = none).
##   T1 last spot (G1) · T2 auto-X after a cake: row, col, patch, 8 neighbours (G1, folded into the T1/placing step)
##   T3 confinement (G2) · T4 shared neighbour (G2) · T5 sets k=2,3 (G3) · T6 one-step lookahead (G4) · T7 reject
## Pure logic, RefCounted, no autoloads.
extends RefCounted

const GRADES := {"T1": 1, "T2": 1, "T3": 2, "T4": 2, "T5": 3, "T6": 4, "T7": 5}
const COLS := "ABCDEFGHI"

## Per-board shape (REUSE map: like sudoku/shape.gd, but built per board since patches differ).
static func units(n: int, regions: PackedInt32Array) -> Array:
	var u := []   # [{kind, id, cells}]
	for r in n:
		var c := []; for k in n: c.append(r * n + k)
		u.append({"kind": "row", "id": r, "cells": c})
	for col in n:
		var c := []; for k in n: c.append(k * n + col)
		u.append({"kind": "column", "id": col, "cells": c})
	for g in n:
		var c := []; for i in n * n: if regions[i] == g: c.append(i)
		u.append({"kind": "patch", "id": g, "cells": c})
	return u

static func unit_label(u: Dictionary) -> String:
	match u.kind:
		"row": return "row %d" % (u.id + 1)
		"column": return "column %s" % COLS[u.id]
	return "patch %s" % char(97 + u.id)

static func cell_label(n: int, i: int) -> String:
	return "%s%d" % [COLS[i % n], i / n + 1]

static func touches(n: int, a: int, b: int) -> bool:
	return a != b and absi(a / n - b / n) <= 1 and absi(a % n - b % n) <= 1

## Cells a cake at i rules out (T2): same row / column / patch + 8 neighbours.
static func peers(n: int, regions: PackedInt32Array, i: int) -> Array:
	var out := []
	for j in n * n:
		if j == i: continue
		if j / n == i / n or j % n == i % n or regions[j] == regions[i] or touches(n, i, j): out.append(j)
	return out

static func fresh(n: int) -> Dictionary:
	var cand := PackedByteArray(); cand.resize(n * n); cand.fill(1)
	var cakes := PackedInt32Array(); cakes.resize(n); cakes.fill(-1)
	return {"cand": cand, "cakes": cakes}

static func _has_cake(u: Dictionary, n: int, cakes: PackedInt32Array) -> bool:
	for i in u.cells:
		if cakes[i / n] == i % n: return true
	return false

static func _free(u: Dictionary, cand: PackedByteArray) -> Array:
	var out := []
	for i in u.cells: if cand[i]: out.append(i)
	return out

static func _elims(cand: PackedByteArray, cells: Array) -> Array:
	var out := []
	for i in cells: if cand[i]: out.append(i)
	return out

## The easiest step for the state, {} when solved, {"technique":"contradiction", ...} when a unit has no free cell left.
static func find_step(n: int, regions: PackedInt32Array, cand: PackedByteArray, cakes: PackedInt32Array, max_grade: int = 4) -> Dictionary:
	var U := units(n, regions)
	var open := []
	for u in U:
		if _has_cake(u, n, cakes): continue
		var f := _free(u, cand)
		if f.is_empty(): return {"technique": "contradiction", "grade": 0, "unit": unit_label(u), "cells": [], "eliminations": [], "place": false,
			"explanation": "%s has no free cell left." % unit_label(u).capitalize()}
		open.append({"u": u, "free": f})
	if open.is_empty(): return {}
	# T1 last spot (+ T2 auto-X folded in)
	for o in open:
		if o.free.size() == 1:
			var i: int = o.free[0]
			return {"technique": "T1", "grade": 1, "place": true, "cells": [i], "unit": unit_label(o.u),
				"eliminations": _elims(cand, peers(n, regions, i)),
				"explanation": "%s has one free cell left. Its cake goes here." % unit_label(o.u).capitalize()}
	if max_grade < 2: return {"technique": "T7", "grade": 5}
	# T3 confinement: patch within one row/column -> X rest of that line; line within one patch -> X rest of that patch
	for o in open:
		var u = o.u
		var f: Array = o.free
		if u.kind == "patch":
			for kind in ["row", "column"]:
				var keys := {}
				for i in f: keys[i / n if kind == "row" else i % n] = true
				if keys.size() == 1:
					var k: int = keys.keys()[0]
					var line := []
					for t in n: line.append(k * n + t if kind == "row" else t * n + k)
					var el := _elims(cand, line.filter(func(i): return regions[i] != u.id))
					if not el.is_empty():
						var ln := ("row %d" % (k + 1)) if kind == "row" else ("column %s" % COLS[k])
						return {"technique": "T3", "grade": 2, "place": false, "cells": f, "unit": unit_label(u), "eliminations": el,
							"explanation": "All of %s is in %s, so %s's cake is in %s. Cross out the rest of %s." % [unit_label(u), ln, ln, unit_label(u), ln]}
		else:
			var gs := {}
			for i in f: gs[regions[i]] = true
			if gs.size() == 1:
				var g: int = gs.keys()[0]
				var pcells := []
				for i in n * n: if regions[i] == g and not (i in u.cells): pcells.append(i)
				var el := _elims(cand, pcells)
				if not el.is_empty():
					var pl := "patch %s" % char(97 + g)
					return {"technique": "T3", "grade": 2, "place": false, "cells": f, "unit": unit_label(u), "eliminations": el,
						"explanation": "%s's free cells are all in %s, so %s's cake is there. Cross out the rest of %s." % [unit_label(u).capitalize(), pl, pl, pl]}
	# T4 shared neighbour: a free cell touching every free cell of some unit
	for o in open:
		var f: Array = o.free
		var el := []
		for x in n * n:
			if not cand[x] or x in f: continue
			var all := true
			for y in f:
				if not touches(n, x, y): all = false; break
			if all: el.append(x)
		if not el.is_empty():
			return {"technique": "T4", "grade": 2, "place": false, "cells": f, "unit": unit_label(o.u), "eliminations": el,
				"explanation": "Whichever cell gets %s's cake, these cells would touch it. Cross them out." % unit_label(o.u)}
	if max_grade < 3: return {"technique": "T7", "grade": 5}
	# T5 sets: k open patches whose free cells lie within k rows (or columns) -> X other cells of those lines
	var open_p := open.filter(func(o): return o.u.kind == "patch")
	for k in [2, 3]:
		for combo in _combos(open_p.size(), k):
			for kind in ["row", "column"]:
				var lines := {}; var pids := {}
				for ci in combo:
					pids[open_p[ci].u.id] = true
					for i in open_p[ci].free: lines[i / n if kind == "row" else i % n] = true
				if lines.size() != k: continue
				var el := []
				for i in n * n:
					if cand[i] and not pids.has(regions[i]) and lines.has(i / n if kind == "row" else i % n): el.append(i)
				if not el.is_empty():
					var names := pids.keys().map(func(g): return "patch %s" % char(97 + g))
					var ln := lines.keys().map(func(v): return str(v + 1) if kind == "row" else COLS[v])
					return {"technique": "T5", "grade": 3, "place": false, "cells": [], "unit": ", ".join(names), "eliminations": el,
						"explanation": "%s fit only in %ss %s, so those %ss' cakes are theirs. Cross out the rest of them." % [" and ".join(names), kind, "-".join(ln), kind]}
	if max_grade < 4: return {"technique": "T7", "grade": 5}
	# T6 one-step lookahead: a cake here would leave some open unit with no free cell
	for x in n * n:
		if not cand[x]: continue
		var gone := {x: true}
		for j in peers(n, regions, x): gone[j] = true
		for o in open:
			if x in o.u.cells: continue
			var left := false
			for i in o.free:
				if not gone.has(i): left = true; break
			if not left:
				return {"technique": "T6", "grade": 4, "place": false, "cells": [x], "unit": unit_label(o.u), "eliminations": [x],
					"explanation": "A cake on %s would leave %s with nowhere to go. Cross it out." % [cell_label(n, x), unit_label(o.u)]}
	return {"technique": "T7", "grade": 5}

static func _combos(m: int, k: int) -> Array:
	var out := []
	if k == 2:
		for a in m: for b in range(a + 1, m): out.append([a, b])
	elif k == 3:
		for a in m: for b in range(a + 1, m): for c in range(b + 1, m): out.append([a, b, c])
	return out

static func apply_step(n: int, s: Dictionary, cand: PackedByteArray, cakes: PackedInt32Array) -> void:
	if s.get("place", false):
		var i: int = s.cells[0]
		cakes[i / n] = i % n
		cand[i] = 0
	for j in s.eliminations: cand[j] = 0

## Run the ladder from empty. {solved, grade (1-4, 5 = needs T7, 0 = contradiction), techniques, steps}
static func grade(n: int, regions: PackedInt32Array, max_grade: int = 4) -> Dictionary:
	var st := fresh(n)
	var cand: PackedByteArray = st.cand; var cakes: PackedInt32Array = st.cakes
	var steps := []; var g := 1; var techs := {}
	for guard in 4 * n * n:
		var s := find_step(n, regions, cand, cakes, max_grade)
		if s.is_empty():
			var tl := techs.keys(); tl.sort()
			return {"solved": true, "grade": g, "techniques": tl, "steps": steps, "solution": cakes}
		if s.technique == "contradiction" or s.technique == "T7":
			var tl2 := techs.keys(); tl2.sort()
			return {"solved": false, "grade": 0 if s.technique == "contradiction" else 5, "techniques": tl2, "steps": steps, "solution": cakes}
		apply_step(n, s, cand, cakes)
		steps.append(s); techs[s.technique] = true
		if s.technique == "T1" and not s.eliminations.is_empty(): techs["T2"] = true
		g = max(g, s.grade)
	return {"solved": false, "grade": 5, "techniques": [], "steps": steps, "solution": cakes}

## Compact step log for packs/vectors (SD compact_steps): [{t, c, e}]
static func compact_steps(steps: Array) -> Array:
	return steps.map(func(s): return {"t": s.technique, "c": s.cells, "e": s.eliminations})

static func first_step_summary(n: int, regions: PackedInt32Array) -> Dictionary:
	var st := fresh(n)
	var s := find_step(n, regions, st.cand, st.cakes)
	return {"technique": s.get("technique", ""), "cells": s.get("cells", []), "eliminations": s.get("eliminations", [])}

## Hint engine (SPEC §6 / HN-20; SD next_hint pattern). Player state: cakes as Vector2i list, marks as Vector2i list.
## 1) "fix": a player cake that is not in the solution, or an X on a solution cell. 2) else the easiest next deduction
## from the player's own state (their X marks count as eliminations, auto-X of their cakes applied).
static func next_hint(n: int, regions: PackedInt32Array, solution: PackedInt32Array, player_cakes: Array, player_marks: Array) -> Dictionary:
	for p in player_cakes:
		if solution[p.x] != p.y:
			return {"technique": "fix", "cells": [p.x * n + p.y], "eliminations": [], "place": false,
				"explanation": "This cake doesn't belong to the solution. Let's lift it."}
	for p in player_marks:
		if solution[p.x] == p.y:
			return {"technique": "fix", "cells": [p.x * n + p.y], "eliminations": [], "place": false,
				"explanation": "This X hides a cake spot. Let's clear it."}
	var st := fresh(n)
	var cand: PackedByteArray = st.cand; var cakes: PackedInt32Array = st.cakes
	for p in player_cakes:
		var i: int = p.x * n + p.y
		cakes[p.x] = p.y; cand[i] = 0
		for j in peers(n, regions, i): cand[j] = 0
	for p in player_marks: cand[p.x * n + p.y] = 0
	return find_step(n, regions, cand, cakes)
