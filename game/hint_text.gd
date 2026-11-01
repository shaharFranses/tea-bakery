## Plain-words hint text (SPEC v1.0.1 §6/§16.3 templates, TT-AC-20c/43): colors by their name (D-18: "color",
## never "patch"/"region"), one sentence with exactly one terminal mark, <= 140 characters.
extends RefCounted

const Pal = preload("res://ui/theme/art_palette.gd")
const MAX_LEN := 140
const BANNED := ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "technique", "confinement", "lookahead", "naked", "hidden",
	"x-wing", "candidate", "region", "patch"]

static func color_name(id: int) -> String:
	return Pal.REGION_NAMES[id % Pal.REGION_NAMES.size()]

## Grader step -> player text.
static func text(step: Dictionary) -> String:
	var t := str(step.get("explanation", ""))
	var re := RegEx.create_from_string("(?i)\\b(color|patch) ([a-i])\\b")
	var out := ""; var pos := 0
	for m in re.search_all(t):
		out += t.substr(pos, m.get_start() - pos)
		out += color_name(m.get_string(2).to_lower().unicode_at(0) - 97)
		pos = m.get_end()
	out += t.substr(pos)
	out = out.replace(" has one free cell left. Its cake goes here.", " has one free cell left, so its cake goes here.")
	out = out.replace("'s free cells are all in ", "'s free cells are all in ")
	if out.length() > 0: out = out[0].to_upper() + out.substr(1)
	return out

static func valid(s: String) -> bool:
	if s.length() == 0 or s.length() > MAX_LEN: return false
	var marks := 0
	for ch in s: if ch in [".", "!", "?"]: marks += 1
	if marks != 1 or not (s[s.length() - 1] in [".", "!", "?"]): return false
	for b in BANNED:
		if RegEx.create_from_string("(?i)\\b" + b + "\\b").search(s): return false
	return true
