## Cell states and the tap cycle (SPEC v1.0 D-12, TT-AC-06). Pure logic.
## States: EMPTY, MOLD (player's empty cake mold = the note mark), CAKE. Molds are placed only by the player (no
## auto-molds): they are notes, never validated, never block a cake. Dump values: empty / mold / cake.
extends RefCounted

const EMPTY := 0
const MOLD := 1
const CAKE := 2
const NAMES := ["empty", "mold", "cake"]

const ORDER_MOLD_FIRST := "mold_first"   # default: empty -> mold -> cake -> empty
const ORDER_CAKE_FIRST := "cake_first"   # Settings "Tap order: cake first": empty -> cake -> mold -> empty

## Next stored state for one tap.
static func next_state(state: int, order: String = ORDER_MOLD_FIRST) -> int:
	if order == ORDER_CAKE_FIRST:
		return [CAKE, EMPTY, MOLD][state]    # EMPTY->CAKE, MOLD->EMPTY, CAKE->MOLD
	return [MOLD, CAKE, EMPTY][state]        # EMPTY->MOLD, MOLD->CAKE, CAKE->EMPTY

## Right-click (desktop): toggles the empty mold directly, never produces a cake. On a cake it does nothing.
static func right_click(state: int) -> int:
	if state == CAKE: return CAKE
	return EMPTY if state == MOLD else MOLD
