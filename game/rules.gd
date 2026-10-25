## Tea & Tarts rules (pure, static). Board: n x n, regions = flat PackedInt32Array (row-major, ids 0..n-1).
## A solution / placement is a list of Vector2i(row, col) cake cells.
## Rules: one cake per row, per column and per dough patch (region); no two cakes touch, diagonals included.
extends RefCounted

## Region map is well-formed: n*n cells, exactly n ids 0..n-1, every patch non-empty and 4-connected.
static func regions_valid(n: int, regions: PackedInt32Array) -> bool:
	if n < 1 or regions.size() != n * n: return false
	var counts := []
	counts.resize(n); counts.fill(0)
	for id in regions:
		if id < 0 or id >= n: return false
		counts[id] += 1
	for k in counts:
		if k == 0: return false
	for g in n:
		if not patch_connected(n, regions, g): return false
	return true

static func patch_connected(n: int, regions: PackedInt32Array, g: int, skip: int = -1) -> bool:
	var start := -1
	var total := 0
	for i in regions.size():
		if regions[i] == g and i != skip:
			total += 1
			if start < 0: start = i
	if total == 0: return false
	var seen := {start: true}
	var stack := [start]
	while not stack.is_empty():
		var i: int = stack.pop_back()
		var r := i / n; var c := i % n
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var rr: int = r + d.x; var cc: int = c + d.y
			if rr < 0 or cc < 0 or rr >= n or cc >= n: continue
			var j := rr * n + cc
			if j == skip or regions[j] != g or seen.has(j): continue
			seen[j] = true; stack.append(j)
	return seen.size() == total

## Cells (Vector2i) of a placement that break a rule. Used for the in-game highlight and the win check.
static func conflicts(n: int, regions: PackedInt32Array, cakes: Array) -> Array:
	var bad := {}
	for a in cakes.size():
		for b in range(a + 1, cakes.size()):
			var p: Vector2i = cakes[a]; var q: Vector2i = cakes[b]
			var clash := p.x == q.x or p.y == q.y \
				or regions[p.x * n + p.y] == regions[q.x * n + q.y] \
				or (absi(p.x - q.x) <= 1 and absi(p.y - q.y) <= 1)
			if clash:
				bad[p] = true; bad[q] = true
	return bad.keys()

## Full solution check: exactly n cakes, in bounds, no conflicts (=> one per row/col/patch, none touching).
static func is_solution(n: int, regions: PackedInt32Array, cakes: Array) -> bool:
	if cakes.size() != n or regions.size() != n * n: return false
	for p in cakes:
		if p.x < 0 or p.y < 0 or p.x >= n or p.y >= n: return false
	return conflicts(n, regions, cakes).is_empty()

## Solution as col-per-row array -> Vector2i list.
static func cols_to_cells(cols: PackedInt32Array) -> Array:
	var out := []
	for r in cols.size(): out.append(Vector2i(r, cols[r]))
	return out
