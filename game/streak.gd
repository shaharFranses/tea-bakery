## Streak, "rolling 7 days" (SPEC v0.3 §13.0 U1, vectors §7.1; mirrors spec_assert.py streak()/best_total()).
## Dates are device-local "YYYY-MM-DD" strings. Pure logic.
extends RefCounted

const FORGIVEN_MISS_MIN_GAP_DAYS := 7

static func _day(d: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(d + "T00:00:00") / 86400)

static func streak(S: Array, today: String) -> int:
	if S.is_empty(): return 0
	var days := {}
	for x in S: days[_day(x)] = true
	var mx: int = days.keys().max()
	var t: int = maxi(_day(today), mx)
	var d: int = t if days.has(t) else t - 1
	var count := 0; var last_forgiven := -1
	while true:
		if days.has(d): count += 1; d -= 1; continue
		if days.has(d - 1) and (last_forgiven < 0 or last_forgiven - d >= FORGIVEN_MISS_MIN_GAP_DAYS):
			last_forgiven = d; d -= 1; continue
		return count
	return count

## {best, total} from S alone (best = max streak at each bake date, in date order).
static func best_total(S: Array) -> Dictionary:
	var u := {}
	for x in S: u[x] = true
	var sorted_s: Array = u.keys(); sorted_s.sort()
	var best := 0
	for i in sorted_s.size(): best = maxi(best, streak(sorted_s.slice(0, i + 1), sorted_s[i]))
	return {"best": best, "total": sorted_s.size()}
