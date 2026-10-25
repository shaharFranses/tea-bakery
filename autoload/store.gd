## Save storage (lifted from sudoko_dash autoload/store.gd): CrazyGames data on the portal,
## else localStorage (web) or user://save.json (desktop). Key = "<project name>_save_v1".
extends Node

var KEY: String = str(ProjectSettings.get_setting("application/config/name", "pkd")).to_snake_case() + "_save_v1"

func wait_ready() -> void:
	if not OS.has_feature("web"): return
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 5000:
		if str(JavaScriptBridge.eval("(!window.PKD_CG || window.PKD_CG.ready()) ? 'y' : 'n'")) == "y": return
		await get_tree().create_timer(0.05).timeout

func loading_stop() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.PKD_CG && window.PKD_CG.loadingStop()")

func save(d: Dictionary) -> void:
	var text = JSON.stringify(d)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.PKD_CG ? window.PKD_CG.save(%s, %s) : localStorage.setItem(%s, %s)" % [JSON.stringify(KEY), JSON.stringify(text), JSON.stringify(KEY), JSON.stringify(text)])
	else:
		var f = FileAccess.open("user://save.json", FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()

func load_data() -> Dictionary:
	var text = ""
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(window.PKD_CG ? window.PKD_CG.load(%s) : localStorage.getItem(%s)) || ''" % [JSON.stringify(KEY), JSON.stringify(KEY)])
		text = str(v) if v != null else ""
	elif FileAccess.file_exists("user://save.json"):
		text = FileAccess.get_file_as_string("user://save.json")
	if text == "": return {}
	var d = JSON.parse_string(text)
	return d if d is Dictionary else {}
