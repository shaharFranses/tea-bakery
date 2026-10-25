## tea-bakery: every spec-dependent value in one place (SPEC v0.2, /workspace/pipeline-ops/games/tea-and-tarts/SPEC.md,
## §3.5 tunables + §2 rules text + §9 sizes + §12 ads). Change values here, not in game code. Nothing is locked yet.
extends RefCounted

# Slug "tea-bakery" = filenames, export output, zip, repo ONLY; it is banned in user-visible text (SPEC §3.5
# banned_user_text, QA ruling 10-25), so it is not a string anywhere in game code.
const TITLE_PLACEHOLDER := "Bakery Logic Puzzle"   # = project.godot config/name (HTML <title>) until Growth picks a title

# Board sizes (§9 D-04): mobile max 8x8 (44 px cells at 390 px), 9x9 desktop only
const MIN_N := 5
const MAX_N := 9
const MAX_N_MOBILE := 8
const MIN_TAP_PX := 44.0
const DIFFICULTY_SIZES := {"easy": 5, "medium": 6, "hard": 7, "expert": 8, "master": 9}
# Grade bands per size (SPEC §3.5 chapter table + daily caps; G1..G4, §16.3). GD tunes (D-06). 9x9 = desktop only.
const VALID_BANDS := {5: [1, 2], 6: [1, 2, 3], 7: [1, 2, 3], 8: [1, 2, 3, 4], 9: [2, 3, 4]}
# Runtime generation (SPEC D-21: v1 ships packs; runtime only as a small-board convenience, SD puzzle_source pattern)
const RUNTIME_MAX_N := 6
const RUNTIME_BUDGET_MS := 30.0
const BAND_MAX_ATTEMPTS := 60

# Rules text (§2, ≤3 lines, 12px+)
const RULES_TEXT := "One cake in every row, column and dough patch.\nCakes can't touch, not even at the corners."

# Chapters / hints / ads (§3.4, §3.5 tunables, §12 D-19)
const BOARDS_PER_CHAPTER := 5
const CHAPTERS := 8
const HINTS_FREE_PER_BOARD := 1
const HINTS_CHAPTER1_UNLIMITED_FREE := true
const ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER := 1
# SM ruling 2026-10-25 09:13: NO 5-minute rule (no session floor, no round-count or timer-triggered midgame).
# SPEC v0.3 §3.5/§13.0 U2 still says min_session_s_before_interstitial = 300 -> conflict reported to SM/GD/QA.
# Kept as ONE config value, disabled (0): set to 300000 to restore the spec's floor without code changes.
const ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL := 0
const ADS_CG_MIDGAME_CAP_MS := 180000           # game-enforced cooldown between midgame requests (SM: max 1 per 3 min)
const ADS_INTERSTITIAL_AFTER_DAILY := false
const ADS_REWARDED_USES := ["hint"]

# Save (§12.2): fixed key, never changes after launch
const SAVE_KEY := "tea_bakery_save_v1"
