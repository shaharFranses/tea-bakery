## Bake of the Day state (U1, §7.1): bake dates S, the board's date fixed when the daily is OPENED (finishing after
## midnight counts for that date, V9), completion counted at most once per date (V8), not replayable once done.
## Saved by the caller via to_dict()/from_dict(). Pure logic; the clock comes from game/clock.gd.
extends RefCounted

const Streak = preload("res://game/streak.gd")

var bakes: Array = []          # unique bake dates, sorted
var best_streak := 0
var open_date := ""            # date of the daily currently open ("" = none)

func is_done(date: String) -> bool:
	return date in bakes

## Open the daily for `date` (normally Clock.local_date()). Returns false if it is already done (not replayable).
func open(date: String) -> bool:
	if is_done(date): open_date = ""; return false
	open_date = date
	return true

## Completion of the open daily. Returns {counted, date, streak, best_streak, total_bakes, fresh_line}.
func complete(today: String, forced_date: String = "") -> Dictionary:
	var d := forced_date if forced_date != "" else open_date
	var total_before := bakes.size()
	var counted := d != "" and not is_done(d)
	if counted:
		bakes.append(d); bakes.sort()
	var s := Streak.streak(bakes, today)
	best_streak = maxi(best_streak, maxi(s, Streak.best_total(bakes).best))
	if forced_date == "": open_date = ""
	return {"counted": counted, "date": d, "streak": s, "best_streak": best_streak, "total_bakes": bakes.size(),
		"fresh_line": counted and s == 1 and total_before >= 1}

func summary(today: String) -> Dictionary:
	return {"streak": Streak.streak(bakes, today), "best_streak": maxi(best_streak, Streak.best_total(bakes).best), "total_bakes": bakes.size()}

func to_dict() -> Dictionary:
	return {"bakes": bakes.duplicate(), "best_streak": best_streak}

func from_dict(d: Dictionary) -> void:
	bakes = []
	for x in d.get("bakes", []): if not (str(x) in bakes): bakes.append(str(x))
	bakes.sort(); best_streak = int(d.get("best_streak", 0))
