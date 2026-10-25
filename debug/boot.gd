## Debug-build bootstrap (excluded from Web Release with the rest of debug/). Called by autoload/dbg.gd _ready.
## Installs the QA hooks node (debug/qa_hooks.gd) and the ads mock (debug/ads_mock.gd), so no autoload in the release
## pck names either file (QA-A13 audit patterns).
extends RefCounted

static func start(dbg: Node) -> void:
	# Ads is added after Dbg (autoload order), so install the mock deferred (FIFO: before qa_hooks' deferred URL apply)
	_install_mock.call_deferred(dbg)
	dbg.hooks = load("res://debug/qa_hooks.gd").new()
	dbg.enabled = true
	dbg.add_child(dbg.hooks)

static func _install_mock(dbg: Node) -> void:
	var ads = dbg.get_node_or_null("/root/Ads")
	if ads == null: return
	ads.mock = load("res://debug/ads_mock.gd").new()
	if ads.mode == "none": ads.mode = ads.mock.DEFAULT_MODE
	ads.changed.emit()
