## Chapter-based ad policy (SPEC v0.2 §12 D-19). Pure logic.
extends GutTest
const AdPolicy = preload("res://game/ad_policy.gd")
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
