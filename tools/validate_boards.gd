## H5 pack verification (SPEC §13.1): every SHIPPED board - 96 chapter boards (c1-b1..c8-b12, SPEC v1.1) + the 400-board daily
## pool - is re-verified: valid regions, exactly one solution (solver limit 2) equal to the stored one, ladder grade ==
## stored grade (no T7), chapter size/grade == the spec table (via the levels files), all region maps distinct.
## usage: godot --headless --path . -s tools/validate_boards.gd -- <out.json>   (non-zero exit on any failure)
extends SceneTree
const Chapters = preload("res://game/chapters.gd")
const DailyPool = preload("res://game/daily_pool.gd")
const Solver = preload("res://game/solver.gd")
const Grader = preload("res://game/grader.gd")
const Rules = preload("res://game/rules.gd")

func _check(p: Dictionary, out: Array, seen: Dictionary) -> bool:
	var errs := []
	if not Rules.regions_valid(p.n, p.regions): errs.append("regions invalid")
	var sv = Solver.new()
	var sols: Array = sv.solve(p.n, p.regions, 2)
	if sols.size() != 1: errs.append("%d solutions" % sols.size())
	elif sols[0] != p.solution: errs.append("solution != stored")
	var g: Dictionary = Grader.grade(p.n, p.regions)
	if not g.solved or int(g.grade) != int(p.grade): errs.append("grade %s != stored %d" % [g.grade, p.grade])
	var key := "%d:%s" % [p.n, ",".join(Array(p.regions).map(func(v): return str(v)))]
	if seen.has(key): errs.append("duplicate of %s" % seen[key])
	seen[key] = p.id
	out.append({"id": p.id, "n": p.n, "grade": p.grade, "nodes": sv.nodes, "ok": errs.is_empty(), "errors": errs})
	return errs.is_empty()

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "validate_boards.json"
	var out := []; var seen := {}; var ok := true
	for ch in range(1, 9):
		for b in range(1, Chapters.BOARDS + 1):
			var p := Chapters.board(ch, b)
			if p.is_empty(): out.append({"id": "c%d-b%d" % [ch, b], "ok": false, "errors": ["missing"]}); ok = false; continue
			ok = _check(p, out, seen) and ok
	var bs: Array = DailyPool.doc().boards
	for j in bs.size():
		var date := Time.get_date_string_from_unix_time((DailyPool.day_number(DailyPool.EPOCH) + j) * 86400)
		var p := DailyPool.board(date)
		if int(p.index) != j: out.append({"id": "d-%03d" % j, "ok": false, "errors": ["index %d" % p.index]}); ok = false; continue
		ok = _check(p, out, seen) and ok
	var bad := out.filter(func(x): return not x.ok)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"pass": ok and bs.size() == 400, "chapter_boards": 8 * Chapters.BOARDS, "daily_boards": bs.size(), "failures": bad, "boards": out}, " "))
	f.close()
	print("validate_boards: %s: %d boards (%d chapter + %d daily), %d failures -> %s" % ["PASS" if ok and bs.size() == 400 else "FAIL", out.size(), out.size() - bs.size(), bs.size(), bad.size(), path])
	quit(0 if ok and bs.size() == 400 else 1)
