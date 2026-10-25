## tea-bakery backtracking solver. Row by row with column / patch bitmasks and the no-touch rule
## (in a row-by-row search, touching can only happen between consecutive rows: |col - prev_col| <= 1).
## count() stops at `limit` (use 2 for the uniqueness check). Returns 0 for boards with no solution.
extends RefCounted

var n := 0
var regions := PackedInt32Array()
var limit := 2
var found: Array = []          # PackedInt32Array col-per-row, up to `limit`
var nodes := 0                 # search nodes visited (a rough difficulty signal)
var _cols := PackedInt32Array()

func solve(size: int, reg: PackedInt32Array, max_solutions: int = 2) -> Array:
	n = size; regions = reg; limit = max_solutions
	found = []; nodes = 0
	if n < 1 or reg.size() != n * n: return found
	for id in reg:
		if id < 0 or id >= n: return found      # malformed map: no solutions
	_cols = PackedInt32Array(); _cols.resize(n)
	_rec(0, 0, 0, -9)
	return found

func count(size: int, reg: PackedInt32Array, max_solutions: int = 2) -> int:
	return solve(size, reg, max_solutions).size()

func _rec(r: int, colmask: int, regmask: int, prev: int) -> void:
	if found.size() >= limit: return
	if r == n:
		found.append(_cols.duplicate()); return
	nodes += 1
	var base := r * n
	for c in n:
		if colmask & (1 << c): continue
		if c >= prev - 1 and c <= prev + 1: continue
		var g := regions[base + c]
		if regmask & (1 << g): continue
		_cols[r] = c
		_rec(r + 1, colmask | (1 << c), regmask | (1 << g), c)
		if found.size() >= limit: return
