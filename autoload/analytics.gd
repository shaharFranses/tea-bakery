## Analytics: NO analytics at launch (SPEC v1.0 §12.4, Shahar Q2, TT-AC-53). The §12.4 event functions are wired in at
## their trigger points but go to a NO-OP sink in every build: no network request, no third-party SDK, no storage.
## Debug builds with QA hooks copy each event into a 200-event ring (PKD_QA.dump().analytics) so the hooks stay testable.
## A production sink is post-launch (TT-AC-34..36, §13.3). Autoload "Analytics".
extends Node

const RING_MAX := 200
var sink := "noop"             # reported in the debug dump as analytics_sink
var ring: Array = []           # debug only (stays empty in release)
var session_id := ""

func _ready() -> void:
	session_id = "%x%x" % [Time.get_ticks_usec(), randi()]    # per page load, never stored

func chapter_start(chapter_id: int, board_size: int, boards_in_chapter: int, chapters_completed_before: int) -> void:
	_emit("chapter_start", {"chapter_id": chapter_id, "board_size": board_size, "boards_in_chapter": boards_in_chapter,
		"chapters_completed_before": chapters_completed_before})

func chapter_complete(params: Dictionary) -> void:
	_emit("chapter_complete", params)

func board_start(board_id: String, mode: String, board_size: int, grade: int, is_replay: bool) -> void:
	_emit("board_start", {"board_id": board_id, "mode": mode, "board_size": board_size, "grade": grade, "is_replay": is_replay})

func board_complete(board_id: String, mode: String, board_size: int, grade: int, duration_s: float, hints_used: int, undo_count: int, is_replay: bool) -> void:
	_emit("board_complete", {"board_id": board_id, "mode": mode, "board_size": board_size, "grade": grade,
		"duration_s": duration_s, "hints_used": hints_used, "undo_count": undo_count, "is_replay": is_replay})

func hint_used(board_id: String, kind: String, technique: String) -> void:
	_emit("hint_used", {"board_id": board_id, "kind": kind, "technique": technique})

func daily_complete(local_date: String, board_size: int, duration_s: float, hints_used: int, streak: int) -> void:
	_emit("daily_complete", {"local_date": local_date, "board_size": board_size, "duration_s": duration_s,
		"hints_used": hints_used, "streak": streak})

## The one sink. No-op: nothing leaves the page, nothing is stored.
func _emit(event: String, params: Dictionary) -> void:
	if not (OS.is_debug_build() and Dbg.hooks): return
	var e := params.duplicate()
	e["event"] = event; e["ev_v"] = 1; e["session_id"] = session_id; e["t_ms"] = Time.get_ticks_msec()
	ring.append(e)
	if ring.size() > RING_MAX: ring.pop_front()
