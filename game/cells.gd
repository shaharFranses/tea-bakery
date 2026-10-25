## Cell states and the tap cycle (SPEC v1.0 D-12, D-13, TT-AC-06, TT-AC-22). Pure logic.
## States: EMPTY, MOLD (player's empty cake mold = the note mark), CAKE; MOLD_AUTO is DERIVED (auto-mold): an EMPTY cell in
## a cake's row, column, color region or 8-neighbourhood while Settings "Auto-molds" is on. It is never stored, so removing
## a cake removes only its own auto-molds and a player MOLD is never downgraded. Molds are notes: never validated, never
## block a cake. Dump values: empty / mold / mold_auto / cake.
extends RefCounted

const Grader = preload("res://game/grader.gd")

const EMPTY := 0
const MOLD := 1
const CAKE := 2
const MOLD_AUTO := 3          # display/dump only
const NAMES := ["empty", "mold", "cake", "mold_auto"]

const ORDER_MOLD_FIRST := "mold_first"   # default: empty -> mold -> cake -> empty
const ORDER_CAKE_FIRST := "cake_first"   # Settings "Tap order: cake first": empty -> cake -> mold -> empty

## Next stored state for one tap. An auto-mold cell is stored EMPTY, so it cycles like an empty cell.
static func next_state(state: int, order: String = ORDER_MOLD_FIRST) -> int:
	if state == MOLD_AUTO: state = EMPTY
	if order == ORDER_CAKE_FIRST:
		return [CAKE, EMPTY, MOLD][state]    # EMPTY->CAKE, MOLD->EMPTY, CAKE->MOLD
	return [MOLD, CAKE, EMPTY][state]        # EMPTY->MOLD, MOLD->CAKE, CAKE->EMPTY

## Right-click (desktop): toggles the empty mold directly, never produces a cake. On a cake it does nothing.
static func right_click(state: int) -> int:
	if state == CAKE: return CAKE
	return EMPTY if state == MOLD else MOLD

## Cells shown as MOLD_AUTO for the stored `cells` (n*n), or {} when auto-molds are off.
static func auto_molds(n: int, regions: PackedInt32Array, cells: PackedInt32Array, on: bool = true) -> Dictionary:
	var out := {}
	if not on: return out
	for i in n * n:
		if cells[i] != CAKE: continue
		for j in Grader.peers(n, regions, i):
			if cells[j] == EMPTY: out[j] = true
	return out

## Display state of cell i (EMPTY/MOLD/CAKE/MOLD_AUTO).
static func shown(i: int, cells: PackedInt32Array, auto: Dictionary) -> int:
	return MOLD_AUTO if cells[i] == EMPTY and auto.has(i) else cells[i]
