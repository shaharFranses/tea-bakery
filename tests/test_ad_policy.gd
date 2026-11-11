## Chapter-based ad policy (SPEC v0.2 §12 D-19). Pure logic.
extends GutTest
const AdPolicy = preload("res://game/ad_policy.gd")
const Cfg = preload("res://game/tt_config.gd")
const MIN := 60 * 1000

func test_no_ads_before_chapter1_ends():
	var p = AdPolicy.new(0, 0)
	assert_eq(p.chapter_end_offer(1, 30 * MIN, true), "none", "chapter 1 not completed yet")
	p.on_board_start(); p.on_hint_used("free")
	assert_eq(p.hint_offer(2, "daily", true), "none", "no rewarded before chapter 1 ends (daily, free used)")
	assert_eq(p.board_end_offer(), "none")

func test_midgame_only_at_chapter_end_after_ch1_and_5min():
	var p = AdPolicy.new(0, 0)
	p.on_chapter_completed(1)
	assert_eq(p.chapter_end_offer(1, 4 * MIN, true), "none", "session < 5 min floor")
	assert_eq(p.chapter_end_offer(1, 6 * MIN, false), "none", "ads unavailable")
	assert_eq(p.chapter_end_offer(1, 6 * MIN, true), "midgame")
	p.on_midgame_shown(6 * MIN)
	p.on_chapter_completed(2)
	assert_eq(p.chapter_end_offer(2, 8 * MIN, true), "none", "CG 3-min cap")
	assert_eq(p.chapter_end_offer(2, 9 * MIN + 1, true), "midgame")
	assert_eq(p.board_end_offer("chapter"), "none"); assert_eq(p.board_end_offer("daily"), "none")

func test_never_pair_rewarded_and_midgame():
	var p = AdPolicy.new(0, 1)
	p.on_board_start(); p.on_hint_used("free")
	assert_eq(p.hint_offer(2, "chapter", true), "rewarded")
	p.on_hint_used("rewarded")
	p.on_chapter_completed(2)
	assert_eq(p.chapter_end_offer(2, 20 * MIN, true), "none", "rewarded since the last board started")
	p.on_board_start()
	assert_eq(p.chapter_end_offer(2, 20 * MIN, true), "midgame")

func test_hints():
	var p = AdPolicy.new(0, 0)
	p.on_board_start()
	for i in 5:
		assert_eq(p.hint_offer(1, "chapter", true), "free", "chapter 1 unlimited free"); p.on_hint_used("free")
	p = AdPolicy.new(0, 1); p.on_board_start()
	assert_eq(p.hint_offer(3, "chapter", true), "free"); p.on_hint_used("free")
	assert_eq(p.hint_offer(3, "chapter", true), "rewarded")
	assert_eq(p.hint_offer(3, "chapter", false), "none", "hidden when ad unavailable/adblocked")
	p.on_board_start()
	assert_eq(p.hint_offer(3, "chapter", true), "free", "free hint resets each board")

## The policy itself enforces >= 3 min between interstitials (fake clock); the SDK cap is only a backstop.
func test_policy_enforces_3min_gap_with_fake_clock():
	var clock := 0
	var p = AdPolicy.new(clock, 0)
	for ch in range(1, 6): p.on_chapter_completed(ch)
	clock = 6 * MIN
	assert_eq(p.chapter_end_offer(1, clock, true), "midgame"); p.on_midgame_shown(clock)
	for dt in [1000, 60 * 1000, 179 * 1000, 179999]:
		assert_eq(p.chapter_end_offer(2, clock + dt, true), "none", "gap %d ms < 180000" % dt)
	assert_eq(p.chapter_end_offer(2, clock + 180000, true), "midgame", "exactly 3 min later")
	p.on_midgame_shown(clock + 180000)
	assert_eq(p.chapter_end_offer(3, clock + 180000 + 90000, true), "none")
	assert_eq(p.chapter_end_offer(3, clock + 360000, true), "midgame")

## AD-17 / BR-3 (SPEC v1.0 §13.0 U2, §13.1, TT-AC-17) on the U2 session clock, values from tt_config (= spec §3.5):
## given a chapter end with chapter 1 done: 299 s -> denied "session_s<300", 300 s -> allowed; 179 s since the previous
## allowed request -> denied "gap<180s", 180 s -> allowed. Entries {t, session_s, origin, allowed, reason}, reasons verbatim.
const REASONS := ["ok", "session_s<300", "gap<180s", "chapter1_not_done", "not_chapter_end", "daily", "replay",
	"rewarded_since_b5", "before_first_gameplayStart", "ad_unavailable"]

func test_ad17_edges_299_300_and_179_180_spec_reasons():
	var floor_ms: int = Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL; var gap_ms: int = Cfg.ADS_CG_MIDGAME_CAP_MS
	var p = AdPolicy.new(0, 0)
	var e = p.decide(1, floor_ms + 60000, true)
	assert_eq(e.keys(), ["t", "session_s", "origin", "allowed", "reason"], "spec entry shape")
	assert_eq([e.allowed, e.reason], [false, "chapter1_not_done"])
	p.on_chapter_completed(1)
	e = p.decide(1, floor_ms - 1000, true)
	assert_eq([e.allowed, e.reason, e.session_s], [false, "session_s<300", 299.0], "299 s: denied by the floor")
	e = p.decide(1, floor_ms, true)
	assert_eq([e.allowed, e.reason, e.session_s], [true, "ok", 300.0], "300 s: allowed")
	p.on_chapter_completed(2)
	e = p.decide(2, floor_ms + gap_ms - 1000, true)
	assert_eq([e.allowed, e.reason], [false, "gap<180s"], "179 s after the previous request")
	e = p.decide(2, floor_ms + gap_ms, true)
	assert_eq([e.allowed, e.reason], [true, "ok"], "180 s after")
	var seen := {"ok": true, "session_s<300": true, "gap<180s": true, "chapter1_not_done": true}
	for c in [["board_end", "chapter", "not_chapter_end"], ["timer", "chapter", "not_chapter_end"],
			["chapter_end", "daily", "daily"], ["chapter_end", "replay", "replay"]]:
		e = p.decide(2, 2000 * 1000, true, c[0], c[1]); seen[e.reason] = true
		assert_eq([e.allowed, e.reason], [false, c[2]])
	var q = AdPolicy.new(0, 1)
	e = q.decide(1, 900 * 1000, true, "chapter_end", "chapter", false); seen[e.reason] = true
	assert_eq(e.reason, "before_first_gameplayStart")
	e = q.decide(1, 900 * 1000, false); seen[e.reason] = true
	assert_eq(e.reason, "ad_unavailable")
	q.on_board_start(); q.on_hint_used("rewarded")
	e = q.decide(1, 900 * 1000, true); seen[e.reason] = true
	assert_eq(e.reason, "rewarded_since_b5")
	assert_eq(seen.keys().size(), REASONS.size(), "all 10 spec reasons exercised")
	for r in seen: assert_true(r in REASONS, "reason %s in the spec enum" % r)

## SPEC v1.4 level-break slot: due after b4 and b8 only; same floors as the chapter-end slot; shares the 180 s gap.
func test_level_break_slot():
	assert_eq(Cfg.ADS_LEVEL_BREAK_EVERY, 4)
	var due := []
	for b in range(1, 13): if AdPolicy.level_break_due(b, 12): due.append(b)
	assert_eq(due, [4, 8], "b12 is the chapter end, not a level break")
	assert_false(AdPolicy.level_break_due(0, 12))
	var floor_ms: int = Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL; var gap_ms: int = Cfg.ADS_CG_MIDGAME_CAP_MS
	var p = AdPolicy.new(0, 0)
	var e = p.decide(1, floor_ms * 3, true, "level_break")
	assert_eq([e.allowed, e.reason, e.origin], [false, "chapter1_not_done", "level_break"], "no ads inside chapter 1")
	p.on_chapter_completed(1)
	e = p.decide(2, floor_ms - 1000, true, "level_break"); assert_eq(e.reason, "session_s<300")
	e = p.decide(2, floor_ms, true, "level_break")
	assert_eq([e.allowed, e.reason], [true, "ok"], "chapter 2 in progress, chapter 1 done: allowed")
	e = p.decide(2, floor_ms + gap_ms - 1000, true, "level_break"); assert_eq(e.reason, "gap<180s")
	p.on_chapter_completed(2)
	e = p.decide(2, floor_ms + gap_ms - 1, true, "chapter_end"); assert_eq(e.reason, "gap<180s", "one shared gap for both slots")
	e = p.decide(2, floor_ms + gap_ms, true, "chapter_end"); assert_true(e.allowed)
	e = p.decide(3, 9000 * 1000, true, "level_break", "replay"); assert_eq(e.reason, "replay")
	e = p.decide(3, 9000 * 1000, true, "level_break", "daily"); assert_eq(e.reason, "daily")
	e = p.decide(3, 9000 * 1000, false, "level_break"); assert_eq(e.reason, "ad_unavailable")
	p.on_board_start(); p.on_hint_used("rewarded")
	e = p.decide(3, 9000 * 1000, true, "level_break"); assert_eq(e.reason, "rewarded_since_b5")
	e = p.decide(3, 9000 * 1000, true, "board_end"); assert_eq(e.reason, "not_chapter_end", "any other origin is still refused")
