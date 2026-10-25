## tea-bakery chapter-based ad policy (SPEC v0.3 §12 D-19 + §13.0 U2, SM ruling 10-25). Pure logic, per session, not saved.
## Adapted from sudoku-dash dev a795a1a game/ad_policy.gd (3 rounds / 5 min results offer), which SPEC §12 replaces:
##  - no ads of any kind before chapter 1 ends (no rewarded either);
##  - interstitial ("midgame") only at the chapter-end slot, from the end of chapter 1 on, if session play >= 5 min,
##    >= 180 s since the previous midgame REQUEST (game-enforced cooldown, SM 10-25: max 1 per 3 min; NO 5-minute rule,
##    no round-count or timer-triggered midgame: decide() only runs at the chapter-end slot),
##    and no rewarded ad since that chapter's last board started; every decision has a reason (decide());
##  - never after a single board, never after the daily, never in the tutorial;
##  - rewarded only for hints: chapter 1 hints free + unlimited; later 1 free per board, then rewarded (if available).
extends RefCounted

const Cfg = preload("res://game/tt_config.gd")

var session_start_ms: int = 0
var chapters_completed: int = 0         # highest chapter finished (from the save)
var last_midgame_ms: int = -1
var rewarded_since_board_start := false
var free_hints_used_this_board := 0

func _init(start_ms: int = 0, completed_chapters: int = 0) -> void:
	session_start_ms = start_ms
	chapters_completed = completed_chapters

func ads_unlocked() -> bool:
	return chapters_completed >= Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER

func on_board_start() -> void:
	rewarded_since_board_start = false
	free_hints_used_this_board = 0

func on_chapter_completed(chapter: int) -> void:
	chapters_completed = max(chapters_completed, chapter)

## Between boards: always "none" (interstitials only at chapter ends).
func board_end_offer(_mode: String = "chapter") -> String:
	return "none"

## Chapter-end slot (player taps "Next chapter" / "Home" on the chapter-end screen): "midgame" or "none".
## now_ms is on the session clock base passed to _init (tests use a fake clock).
func chapter_end_offer(chapter: int, now_ms: int, ads_available: bool) -> String:
	return "midgame" if decide(chapter, now_ms - session_start_ms, ads_available).decision == "requested" else "none"

## Every midgame decision with its reason (BR-3 / AD-17; the caller logs it to Ads.call_log, denials included).
## session_ms = U2 session clock (game/clock.gd session_ms()). The game enforces both the 300 s floor and the 180 s gap
## itself (SPEC v0.3 §13.0 U2); the CG SDK cap is only a backstop. Order of checks = order of reasons below.
## {kind:"midgame", origin, mode, chapter, session_s, since_prev_midgame_s (-1 = none yet), decision: requested|denied, reason}
func decide(chapter: int, session_ms: int, ads_available: bool, origin: String = "chapter_end", mode: String = "chapter", ads_mode: String = "") -> Dictionary:
	var since := -1.0 if last_midgame_ms < 0 else (session_ms - last_midgame_ms) / 1000.0
	var reason := ""
	if origin != "chapter_end": reason = "not_chapter_end"                       # never after a board / in the tutorial
	elif mode == "daily": reason = "daily"                                        # never before/after/during the daily
	elif mode == "replay": reason = "replay"
	elif chapter < Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER or chapters_completed < Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER: reason = "chapter1_not_done"
	elif chapters_completed < chapter: reason = "chapter_not_completed"
	elif Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL > 0 and session_ms < Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL: reason = "session_lt_%ds" % (Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL / 1000)   # disabled (SM)
	elif last_midgame_ms >= 0 and session_ms - last_midgame_ms < Cfg.ADS_CG_MIDGAME_CAP_MS: reason = "cooldown_%ds" % (Cfg.ADS_CG_MIDGAME_CAP_MS / 1000)
	elif rewarded_since_board_start: reason = "rewarded_since_chapter_last_board"   # never pair rewarded + midgame
	elif ads_mode == "qa_off": reason = "qa_mode"                                 # ?qa=1 without an ads mock: never a real ad
	elif not ads_available: reason = "ads_unavailable"
	var e := {"kind": "midgame", "origin": origin, "mode": mode, "chapter": chapter, "session_s": session_ms / 1000.0,
		"since_prev_midgame_s": since, "decision": "denied" if reason != "" else "requested", "reason": reason if reason != "" else "ok"}
	if reason == "": last_midgame_ms = session_ms      # the gap counts from the previous REQUEST (U2)
	return e

## Kept for callers that record the show separately (now_ms on the _init clock base). Requests already record.
func on_midgame_shown(now_ms: int) -> void:
	last_midgame_ms = now_ms - session_start_ms

## Hint button: "free", "rewarded" (show the 🎬 confirm modal) or "none" (button hidden).
func hint_offer(chapter: int, mode: String, rewarded_available: bool) -> String:
	if mode != "daily" and chapter <= 1 and Cfg.HINTS_CHAPTER1_UNLIMITED_FREE: return "free"
	if free_hints_used_this_board < Cfg.HINTS_FREE_PER_BOARD: return "free"
	if rewarded_available and ads_unlocked() and "hint" in Cfg.ADS_REWARDED_USES: return "rewarded"
	return "none"

func on_hint_used(kind: String) -> void:
	if kind == "free": free_hints_used_this_board += 1
	elif kind == "rewarded": rewarded_since_board_start = true
