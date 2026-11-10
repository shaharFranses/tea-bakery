## Game clocks (SPEC v0.3 §13.0 U1/U2). Static, no autoload. Everything that needs "today" or session_s reads here.
##  * local_date(): device-local date "YYYY-MM-DD" (daily board, streak). Debug hooks may override the local clock at
##    runtime (it keeps running from the override: BR-2 "now:YYYY-MM-DDTHH:MM", H3 ?date=).
##  * session_s(): U2 wall-clock seconds since the FIRST gameplayStart of this page load (menus, ads, hidden tab count;
##    reload = new session). 0 before the session starts. Debug hooks may set it (BR-3 "session_s:N", H3 offset).
## The setters are plain API (unit tests use them); only debug/ code calls them in a build.
extends RefCounted

static var _session_start_ticks: int = -1
static var _session_adjust_ms: int = 0
static var _now_override_unix: int = -1      # device-local wall time (as if UTC) at _now_override_ticks
static var _now_override_ticks: int = 0

static func start_session() -> void:
	if _session_start_ticks < 0: _session_start_ticks = Time.get_ticks_msec()

static func session_started() -> bool:
	return _session_start_ticks >= 0

static func session_ms() -> int:
	if _session_start_ticks < 0: return _session_adjust_ms if _session_adjust_ms > 0 else 0
	return Time.get_ticks_msec() - _session_start_ticks + _session_adjust_ms

static func session_s() -> float:
	return session_ms() / 1000.0

## Set the session clock to exactly `s` seconds now (keeps running from there).
static func set_session_s(s: float) -> void:
	var raw := 0 if _session_start_ticks < 0 else Time.get_ticks_msec() - _session_start_ticks
	_session_adjust_ms = int(round(s * 1000.0)) - raw

static func add_session_offset_ms(ms: int) -> void:
	_session_adjust_ms += ms

## Device-local "wall" seconds (local time expressed as if UTC, for date math).
static func local_unix() -> int:
	if _now_override_unix >= 0:
		return _now_override_unix + (Time.get_ticks_msec() - _now_override_ticks) / 1000
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return int(Time.get_unix_time_from_system()) + bias

static func local_date() -> String:
	return Time.get_date_string_from_unix_time(local_unix())

static func local_datetime() -> String:
	return Time.get_datetime_string_from_unix_time(local_unix())

## True for a plain "YYYY-MM-DD" (checked BEFORE any Godot ISO parser call: a bad string there logs a USER ERROR).
static func is_iso_date(s: String) -> bool:
	if s.length() != 10 or s[4] != "-" or s[7] != "-": return false
	for i in [0, 1, 2, 3, 5, 6, 8, 9]:
		if not s[i].is_valid_int(): return false
	var y := s.substr(0, 4).to_int(); var m := s.substr(5, 2).to_int(); var d := s.substr(8, 2).to_int()
	if m < 1 or m > 12 or d < 1: return false
	var dim := [31, 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return d <= dim[m - 1]

## QA/debug date argument -> "YYYY-MM-DD", or "" if it is not a date. "today" / "now" / "" resolve to local_date(),
## which already honours a set_date override (S1-01: PKD_QA.show("daily:today")).
static func resolve_date(s: String) -> String:
	var t := s.strip_edges().to_lower()
	if t in ["", "today", "now"]: return local_date()
	return s.strip_edges() if is_iso_date(s.strip_edges()) else ""

## "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM[:SS]" (device-local). Returns false on a bad string (no parser call, no USER ERROR).
static func set_local_now(s: String) -> bool:
	var t := s if "T" in s else s + "T12:00:00"
	if t.length() == 16: t += ":00"
	if t.length() != 19 or not is_iso_date(t.substr(0, 10)) or t[10] != "T" or t[13] != ":" or t[16] != ":": return false
	for i in [11, 12, 14, 15, 17, 18]:
		if not t[i].is_valid_int(): return false
	if t.substr(11, 2).to_int() > 23 or t.substr(14, 2).to_int() > 59 or t.substr(17, 2).to_int() > 59: return false
	var u := Time.get_unix_time_from_datetime_string(t)
	if u == 0 and not t.begins_with("1970-01-01"): return false
	_now_override_unix = u; _now_override_ticks = Time.get_ticks_msec()
	return true

static func reset() -> void:
	_session_start_ticks = -1; _session_adjust_ms = 0; _now_override_unix = -1
