## Ad tunables in game/tt_config.gd == SPEC v1.0 §3.5 tunables.ads. Reads the live spec when it is on the box, else the
## synced copy data/spec_tunables.json (and then also checks the copy is current when the spec exists).
extends GutTest
const Cfg = preload("res://game/tt_config.gd")
const SPEC := "/workspace/pipeline-ops/games/tea-and-tarts/SPEC.md"

func _spec_ads() -> Dictionary:
	if FileAccess.file_exists(SPEC):
		var t := FileAccess.get_file_as_string(SPEC)
		var re := RegEx.create_from_string('"ads":\\s*(\\{[^\\n]*?\\})\\s*,\\s*\\n')
		var m := re.search(t)
		if m: return JSON.parse_string(m.get_string(1))
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/spec_tunables.json")).ads

func test_ads_tunables_match_spec():
	var a := _spec_ads()
	assert_false(a.is_empty())
	assert_eq(Cfg.ADS_MIN_SESSION_MS_BEFORE_INTERSTITIAL, int(a.min_session_s_before_interstitial) * 1000)
	assert_eq(Cfg.ADS_CG_MIDGAME_CAP_MS, int(a.min_gap_between_midgame_s) * 1000)
	assert_eq(Cfg.ADS_FIRST_INTERSTITIAL_AFTER_CHAPTER, int(a.first_interstitial_after_chapter))
	assert_eq(Cfg.ADS_INTERSTITIAL_AFTER_DAILY, bool(a.interstitial_after_daily))
	assert_eq(Cfg.ADS_REWARDED_USES, a.rewarded_uses)
	var synced = JSON.parse_string(FileAccess.get_file_as_string("res://data/spec_tunables.json")).ads
	assert_eq(synced, a, "data/spec_tunables.json in sync with the spec")
