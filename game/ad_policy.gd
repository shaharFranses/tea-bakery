## tea-bakery chapter-based ad policy (SPEC v0.2 §12 D-19, SM ruling 10-25). Pure logic, per session, not saved.
## Adapted from sudoku-dash dev a795a1a game/ad_policy.gd (3 rounds / 5 min results offer), which SPEC §12 replaces:
##  - no ads of any kind before chapter 1 ends (no rewarded either);
##  - interstitial ("midgame") only at the chapter-end slot, from the end of chapter 1 on, if session play >= 5 min,
##    >= 3 min since the last midgame (CG cap), and no rewarded ad since that chapter's last board started;
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
func chapter_end_offer(chapter: int, now_ms: int, ads_available: bool) -> String:
	if not ads_available: return "none"
	if chapter < Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER or chapters_completed < chapter: return "none"
	if now_ms - session_start_ms < Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL: return "none"
	if last_midgame_ms >= 0 and now_ms - last_midgame_ms < Cfg.ADS_CG_MIDGAME_CAP_MS: return "none"
	if rewarded_since_board_start: return "none"    # never pair rewarded + midgame between the same two levels
	return "midgame"

func on_midgame_shown(now_ms: int) -> void:
	last_midgame_ms = now_ms

## Hint button: "free", "rewarded" (show the 🎬 confirm modal) or "none" (button hidden).
func hint_offer(chapter: int, mode: String, rewarded_available: bool) -> String:
	if mode != "daily" and chapter <= 1 and Cfg.HINTS_CHAPTER1_UNLIMITED_FREE: return "free"
	if free_hints_used_this_board < Cfg.HINTS_FREE_PER_BOARD: return "free"
	if rewarded_available and ads_unlocked() and "hint" in Cfg.ADS_REWARDED_USES: return "rewarded"
	return "none"

func on_hint_used(kind: String) -> void:
	if kind == "free": free_hints_used_this_board += 1
	elif kind == "rewarded": rewarded_since_board_start = true
