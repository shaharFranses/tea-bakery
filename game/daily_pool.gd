## Bake of the Day pool (SPEC v1.0.2 D-11, §3.5 daily, §5 "date before epoch / beyond pool"): board for a local date =
## pool[(local_date - 2026-11-02) mod 400], clamped to index 0 before the epoch. Pool built offline by tools/build_daily.gd.
extends RefCounted

const PATH := "res://game/levels/daily_pool.json"
const EPOCH := "2026-11-02"
const POOL := 400
static var _doc := {}

static func doc() -> Dictionary:
	if _doc.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_doc = d if d is Dictionary else {}
	return _doc

static func day_number(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400)

static func index_for(date: String) -> int:
	var off := day_number(date) - day_number(EPOCH)
	return 0 if off < 0 else off % POOL

## Last date before the pool wraps back to index 0 (CI warns 60 days ahead).
static func wrap_date() -> String:
	return Time.get_date_string_from_unix_time((day_number(EPOCH) + POOL) * 86400)

## Puzzle dict for main.gd (same shape as Chapters.board()).
static func board(date: String) -> Dictionary:
	var j := index_for(date)
	var e: Dictionary = doc().boards[j]
	var n := int(e.size)
	var reg := PackedInt32Array()
	for row in e.regions:
		for chr in row: reg.append(chr.unicode_at(0) - 65)
	var sol := PackedInt32Array(); for v in e.solution: sol.append(int(v))
	return {"n": n, "regions": reg, "solution": sol, "grade": int(e.grade), "id": str(e.id), "givens": [], "coach": "",
		"targets": [], "tutorial": false, "chapter": 0, "board": 0, "seed": int(e.seed), "index": j, "date": date, "ms": 0.0, "reshapes": 0}
