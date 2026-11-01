## Chapter progress + resume state, saved under the fixed key (SPEC v1.0.1 §12.2, §5 "Returning player", TT-AC-09/23/26).
## Pure logic. Saved: solved board ids, current board marks (player molds + cakes; givens are content, auto-molds are
## recomputed from the cakes + setting; undo stack not saved), recipe cards / décor owned, chapters completed, and
## per-chapter stats for the chapter_complete hook.
extends RefCounted

const Chapters = preload("res://game/chapters.gd")

var solved: Array = []            # board ids, e.g. "c1-b3"
var current_id := ""              # board with saved marks ("" = none)
var current_cells: Array = []     # Cells.EMPTY / MOLD / CAKE per cell
var recipes: Array = []           # chapter numbers whose card is owned
var decor: Array = []
var chapters_completed := 0
var all_baked_seen := false     # §7.2: the "All recipes baked" screen is shown once
var chapter_stats := {}           # "N" -> {hints_used, hints_free, hints_rewarded, active_s, undo_count, conflicts_shown, t0_unix, sessions}

func is_solved(id: String) -> bool:
	return id in solved

func chapter_done(ch: int) -> bool:
	for b in range(1, Chapters.BOARDS + 1):
		if not is_solved("c%d-b%d" % [ch, b]): return false
	return true

## First unsolved chapter board in order among the shipped chapters, or "" when all are solved.
func next_unsolved() -> String:
	for ch in range(1, Chapters.count_available() + 1):
		for b in range(1, Chapters.BOARDS + 1):
			var id := "c%d-b%d" % [ch, b]
			if not is_solved(id): return id
	return ""

## Boot routing (TT-AC-23): saved marks board, else next unsolved chapter board, else "home".
func boot_target() -> String:
	if current_id != "" and not is_solved(current_id) and current_cells.any(func(v): return int(v) != 0): return current_id
	var nx := next_unsolved()
	return nx if nx != "" else "home"

## Every shipped chapter completed (§7.2 end state).
func all_done() -> bool:
	return recipes.size() >= Chapters.count_available()

## Marks a board solved. Returns true the first time (false on a replay).
func mark_solved(id: String) -> bool:
	if current_id == id: current_id = ""; current_cells = []
	if is_solved(id): return false
	solved.append(id)
	return true

## First completion of chapter ch: +1 recipe card and +1 décor (TT-AC-26). Returns false if already owned.
func unlock_chapter(ch: int) -> bool:
	if ch in recipes: return false
	recipes.append(ch); decor.append(ch); recipes.sort(); decor.sort()
	chapters_completed = maxi(chapters_completed, ch)
	return true

func stats(ch: int) -> Dictionary:
	var k := str(ch)
	if not chapter_stats.has(k):
		chapter_stats[k] = {"hints_used": 0, "hints_free": 0, "hints_rewarded": 0, "active_s": 0.0, "undo_count": 0,
			"conflicts_shown": 0, "t0_unix": int(Time.get_unix_time_from_system()), "sessions": 1}
	return chapter_stats[k]

func to_dict() -> Dictionary:
	return {"solved": solved.duplicate(), "current": {"id": current_id, "cells": current_cells.duplicate()},
		"unlocked": {"recipes": recipes.duplicate(), "decor": decor.duplicate()}, "chapters_completed": chapters_completed, "all_baked_seen": all_baked_seen,
		"chapter_stats": chapter_stats.duplicate(true)}

func from_dict(d: Dictionary) -> void:
	solved = []
	for x in d.get("solved", []): if not (str(x) in solved): solved.append(str(x))
	var cur = d.get("current", {})
	current_id = str(cur.get("id", "")) if cur is Dictionary else ""
	current_cells = []
	if cur is Dictionary: for v in cur.get("cells", []): current_cells.append(int(v))
	var u = d.get("unlocked", {})
	recipes = []; decor = []
	if u is Dictionary:
		for v in u.get("recipes", []): recipes.append(int(v))
		for v in u.get("decor", []): decor.append(int(v))
	chapters_completed = int(d.get("chapters_completed", 0))
	all_baked_seen = bool(d.get("all_baked_seen", false))
	var cs = d.get("chapter_stats", {})
	chapter_stats = cs.duplicate(true) if cs is Dictionary else {}
