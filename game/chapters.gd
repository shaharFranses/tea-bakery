## Chapter content (SPEC v1.0.2 §3.2 / §3.5 chapters, §6 tutorial, §16.1 board format). Packs:
## res://game/levels/chapter_NN.json, built offline by tools/build_chapters.gd from the validated pack_<n>_g<band>.json
## boards (D-21: no runtime generation for chapter content) and re-verified in tests/test_chapters.gd.
## Ships chapters 1-8 x 12 levels = 96 boards (SPEC v1.1; b1-b5 = the v1.0.2 boards). Levels are numbered 1..96
## across chapters on the level map (level = (chapter - 1) * BOARDS + board).
extends RefCounted

const RECIPES := ["Scones & clotted cream", "Victoria sponge", "Lemon drizzle", "Jam tarts", "Cherry Bakewell",
	"Strawberry shortcake", "Apple crumble", "Macarons"]   # card 5 = "Cherry Bakewell" (SPEC v1.0.2, SM ruling); names live only here
const DECOR := ["Floral teapot", "Tiered cake stand", "Gingham tablecloth", "Lace doily and teacups", "Vase of sweet peas",
	"Bunting garland", "Cuckoo clock", "Copper kettle"]
const DECOR_FILES := ["decor_1_teapot", "decor_2_cake_stand", "decor_3_gingham", "decor_4_doily_teacups", "decor_5_sweet_peas",
	"decor_6_bunting", "decor_7_cuckoo_clock", "decor_8_copper_kettle"]
const BOARDS := 12
## Cake piece per chapter (SPEC v1.2 §10, D-03 revised): each chapter's board uses the cake of its recipe card.
## Sprites: res://assets/board/cake_<name>_top@2x.png on boards and the level map (top view) and cake_<name>_side@2x.png
## on the home-shelf stands (side view, the chapter trophy). Bake of the Day uses DAILY_CAKE; debug/free boards DEFAULT_CAKE.
## 2026-11-13 (Shahar): chapter 7 is the chocolate tart; custard moved to the daily.
const CAKES := ["scone", "victoria", "lemon", "apricot", "bakewell", "berry", "chocolate", "macaron"]
const DAILY_CAKE := "custard"
const DEFAULT_CAKE := "berry"

## Texture paths of a cake piece: top view (boards, level map) and side view (home-shelf trophy).
static func cake_top(piece: String) -> String: return "res://assets/board/cake_%s_top@2x.png" % piece
static func cake_side(piece: String) -> String: return "res://assets/board/cake_%s_side@2x.png" % piece

static func cake_for(ch: int) -> String:
	return CAKES[ch - 1] if ch >= 1 and ch <= CAKES.size() else DEFAULT_CAKE

## Global level number (1-based) of chapter ch, board b.
static func level(ch: int, b: int) -> int:
	return (ch - 1) * BOARDS + b

## Board id "cN-bM" of a global level number.
static func id_of_level(lv: int) -> String:
	return "c%d-b%d" % [(lv - 1) / BOARDS + 1, (lv - 1) % BOARDS + 1]

## Level number of a board id, 0 if not a chapter id.
static func level_of(id: String) -> int:
	var cb := parse_id(id)
	return level(cb[0], cb[1]) if cb[0] > 0 else 0

static var _cache := {}

static func path(ch: int) -> String:
	return "res://game/levels/chapter_%02d.json" % ch

static func available(ch: int) -> bool:
	return ch >= 1 and FileAccess.file_exists(path(ch))

static func count_available() -> int:
	var k := 0
	while available(k + 1): k += 1
	return k

static func doc(ch: int) -> Dictionary:
	if _cache.has(ch): return _cache[ch]
	if not available(ch): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path(ch)))
	_cache[ch] = d if d is Dictionary else {}
	return _cache[ch]

## "c2-b3" -> [2, 3]; [0, 0] if not a chapter id.
static func parse_id(id: String) -> Array:
	var m := RegEx.create_from_string("^c(\\d+)-b(\\d+)$").search(id)
	return [m.get_string(1).to_int(), m.get_string(2).to_int()] if m else [0, 0]

## Puzzle dict for main.gd: {n, regions (Packed), solution (Packed), grade, id, givens: [Vector2i], coach, target}.
static func board(ch: int, b: int) -> Dictionary:
	var d := doc(ch)
	if d.is_empty() or b < 1 or b > d.boards.size(): return {}
	var e: Dictionary = d.boards[b - 1]
	var n := int(e.size)
	var reg := PackedInt32Array()
	for row in e.regions:
		for chr in row: reg.append(chr.unicode_at(0) - 65)
	var sol := PackedInt32Array(); for v in e.solution: sol.append(int(v))
	var giv := []
	for g in e.get("givens", []): giv.append(Vector2i(int(g[0]), int(g[1])))
	var tgt := []
	for t in e.get("targets", []): tgt.append(Vector2i(int(t[0]), int(t[1])))
	return {"n": n, "regions": reg, "solution": sol, "grade": int(e.grade), "id": str(e.id), "givens": giv,
		"coach": str(e.get("coach", "")), "targets": tgt, "tutorial": e.has("coach"), "chapter": ch, "board": b,
		"seed": int(e.get("seed", 0)), "source_id": str(e.get("source", "")), "ms": 0.0, "reshapes": 0}
