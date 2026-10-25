## tea-bakery: every spec-dependent value in one place (SPEC v0.2, /workspace/pipeline-ops/games/tea-and-tarts/SPEC.md,
## §3.5 tunables + §2 rules text + §9 sizes + §12 ads). Change values here, not in game code. Nothing is locked yet.
extends RefCounted

const WORKING_NAME := "tea-bakery"            # title TBD (SM 10-25); never ship the dropped title
const TITLE_PLACEHOLDER := "tea-bakery"       # stub = working name, no game title (DAY0 / QA R-04) until Growth picks one

# Board sizes (§9 D-04): mobile max 8x8 (44 px cells at 390 px), 9x9 desktop only
const MIN_N := 5
const MAX_N := 9
const MAX_N_MOBILE := 8
const MIN_TAP_PX := 44.0
const DIFFICULTY_SIZES := {"easy": 5, "medium": 6, "hard": 7, "expert": 8, "master": 9}

# Rules text (§2, ≤3 lines, 12px+)
const RULES_TEXT := "One cake in every row, column and dough patch.\nCakes can't touch, not even at the corners."

# Chapters / hints / ads (§3.4, §3.5 tunables, §12 D-19)
const BOARDS_PER_CHAPTER := 5
const CHAPTERS := 8
const HINTS_FREE_PER_BOARD := 1
const HINTS_CHAPTER1_UNLIMITED_FREE := true
const ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER := 1
const ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL := 300000
const ADS_CG_MIDGAME_CAP_MS := 180000
const ADS_INTERSTITIAL_AFTER_DAILY := false
const ADS_REWARDED_USES := ["hint"]

# Save (§12.2): fixed key, never changes after launch
const SAVE_KEY := "tea_bakery_save_v1"
