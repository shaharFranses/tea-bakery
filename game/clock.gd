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

## "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM[:SS]" (device-local). Returns false on a bad string.
static func set_local_now(s: String) -> bool:
	var t := s if "T" in s else s + "T12:00:00"
	if t.length() == 16: t += ":00"
	var u := Time.get_unix_time_from_datetime_string(t)
	if u == 0 and not t.begins_with("1970-01-01"): return false
	_now_override_unix = u; _now_override_ticks = Time.get_ticks_msec()
	return true

static func reset() -> void:
	_session_start_ticks = -1; _session_adjust_ms = 0; _now_override_unix = -1
