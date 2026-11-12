## Save key is a fixed literal (SPEC §12.2, QA plan PS-09): renaming the project (config/name) never changes it.
extends GutTest
func test_save_key_literal():
	assert_eq(Store.KEY, "tea_bakery_save_v1")
func test_save_key_survives_rename():
	var old = ProjectSettings.get_setting("application/config/name")
	ProjectSettings.set_setting("application/config/name", "Some Future Title")
	var fresh = load("res://autoload/store.gd").new()
	assert_eq(fresh.KEY, "tea_bakery_save_v1", "key independent of config/name")
	fresh.free()
	ProjectSettings.set_setting("application/config/name", old)
func test_project_name_is_user_visible_stub_not_slug():
	# config/name -> HTML <title> = the game title (SPEC v1.5); the slug "tea-bakery" stays banned user text (SPEC §3.5)
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Teacake Lane")
	assert_eq(preload("res://game/tt_config.gd").TITLE, "Teacake Lane")
	assert_eq(Store.KEY, "tea_bakery_save_v1", "save key unchanged by the rename")
