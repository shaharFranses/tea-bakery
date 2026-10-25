## Between-round ad decision (lifted from sudoko_dash game/ad_policy.gd). Per-session, not saved.
extends RefCounted

const MIN_SESSION_MS = 5 * 60 * 1000
var session_start_ms: int = 0
var counter: int = 0

func _init(start_ms: int = 0) -> void:
	session_start_ms = start_ms

## Call once per completed round (any mode). Not for retries/abandons/fails.
func on_round_completed() -> void:
	counter += 1

## Returns "midgame", "rewarded" or "none" for this results screen. Never both.
func results_offer(now_ms: int, ads_available: bool) -> String:
	if not ads_available: return "none"
	if counter >= 3 and now_ms - session_start_ms >= MIN_SESSION_MS:
		counter = 0
		return "midgame"
	return "rewarded"
