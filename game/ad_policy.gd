## tea-bakery chapter-based ad policy (SPEC v1.0 §12 D-19 + §13.0 U2 + §13.1 BR-3). Pure logic, per session, not saved.
## Adapted from sudoku-dash dev a795a1a game/ad_policy.gd (3 rounds / 5 min results offer), which SPEC §12 replaces:
##  - no ads of any kind before chapter 1 ends (no rewarded either);
##  - interstitial ("midgame") only at the chapter-end slot, from the end of chapter 1 on, if session play >= 5 min,
##    session_s >= min_session_s_before_interstitial (300, a floor) and >= min_gap_between_midgame_s (180) since the
##    previous midgame request (both game-enforced, SPEC v1.0 U2); no round-count or timer-triggered midgame:
##    decide() only runs at the chapter-end slot;
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
	return "midgame" if decide(chapter, now_ms - session_start_ms, ads_available).allowed else "none"

## Every midgame decision, allowed or denied (SPEC v0.3.1 §13.1 BR-3): {t, session_s, origin, allowed, reason} with
## reason in the spec's enum verbatim: ok, session_s<300, gap<180s, chapter1_not_done, not_chapter_end, daily, replay,
## rewarded_since_b5, before_first_gameplayStart, ad_unavailable. session_ms = U2 clock (game/clock.gd).
## The 180 s gap is game-enforced and counts from the previous allowed REQUEST. Check order = enum order of precedence.
func decide(chapter: int, session_ms: int, ads_available: bool, origin: String = "chapter_end", mode: String = "chapter", session_started: bool = true) -> Dictionary:
	var reason := "ok"
	if origin != "chapter_end": reason = "not_chapter_end"                       # never after a board / tutorial / timer
	elif mode == "daily": reason = "daily"
	elif mode == "replay": reason = "replay"
	elif chapter < Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER or chapters_completed < maxi(chapter, Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER): reason = "chapter1_not_done"
	elif not session_started: reason = "before_first_gameplayStart"
	elif session_ms < Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL: reason = "session_s<%d" % (Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL / 1000)
	elif last_midgame_ms >= 0 and session_ms - last_midgame_ms < Cfg.ADS_CG_MIDGAME_CAP_MS: reason = "gap<%ds" % (Cfg.ADS_CG_MIDGAME_CAP_MS / 1000)
	elif rewarded_since_board_start: reason = "rewarded_since_b5"
	elif not ads_available: reason = "ad_unavailable"
	if reason == "ok": last_midgame_ms = session_ms
	return {"t": Time.get_ticks_msec(), "session_s": session_ms / 1000.0, "origin": origin, "allowed": reason == "ok", "reason": reason}

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
