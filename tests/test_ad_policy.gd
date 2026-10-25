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
	assert_eq(p.chapter_end_offer(1, 4 * MIN, true), "none", "session < 5 min")
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

## AD-17 / BR-3 edges on the U2 session clock: 299 s denied / 300 s requested; 179 s gap denied / 180 s requested;
## every decision carries a reason (denials included).
func test_ad17_edges_299_300_and_179_180_with_reasons():
	var p = AdPolicy.new(0, 0)
	p.on_chapter_completed(1)
	var e = p.decide(1, 299 * 1000, true)
	assert_eq([e.decision, e.reason], ["denied", "session_lt_300s"])
	assert_eq(e.session_s, 299.0); assert_eq(e.since_prev_midgame_s, -1.0)
	e = p.decide(1, 300 * 1000, true)
	assert_eq([e.decision, e.reason], ["requested", "ok"])
	p.on_chapter_completed(2)
	e = p.decide(2, 479 * 1000, true)
	assert_eq([e.decision, e.reason, e.since_prev_midgame_s], ["denied", "gap_lt_180s", 179.0])
	e = p.decide(2, 480 * 1000, true)
	assert_eq([e.decision, e.since_prev_midgame_s], ["requested", 180.0])
	for c in [["board_end", "chapter", "not_chapter_end"], ["chapter_end", "daily", "daily"], ["chapter_end", "replay", "replay"]]:
		e = p.decide(2, 2000 * 1000, true, c[0], c[1])
		assert_eq([e.decision, e.reason], ["denied", c[2]])
	var q = AdPolicy.new(0, 0)
	assert_eq(q.decide(1, 900 * 1000, true).reason, "chapter_not_completed")
	assert_eq(q.decide(0, 900 * 1000, true).reason, "before_chapter1_end")
	q.on_chapter_completed(1)
	assert_eq(q.decide(1, 900 * 1000, false).reason, "ads_unavailable")
	assert_eq(Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL, 300000, "300 s floor is one config value (tt_config.gd)")
