## Save storage (lifted from sudoko_dash autoload/store.gd): CrazyGames data on the portal,
## else localStorage (web) or user://save.json (desktop). Key = "<project name>_save_v1".
extends Node

## SPEC v0.2 §12.2: fixed key, must never change after launch (config/name will change with the title).
const KEY: String = preload("res://game/tt_config.gd").SAVE_KEY

func wait_ready() -> void:
	if not OS.has_feature("web"): return
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 5000:
		if str(JavaScriptBridge.eval("(!window.PKD_CG || window.PKD_CG.ready()) ? 'y' : 'n'")) == "y": return
		await get_tree().create_timer(0.05).timeout

func loading_stop() -> void:
	Ads.sdk("loadingStop", "window.PKD_CG && window.PKD_CG.loadingStop()")   # SD dev a795a1a: via the single SDK gate

var save_writes: Array = []      # [{t_ms, ts, reason}] (TT-AC-49; dumped by the debug hooks)
var corrupt_backed_up := false

func save(d: Dictionary, reason: String = "debounce") -> void:
	var text = JSON.stringify(d)
	save_writes.append({"t_ms": Time.get_ticks_msec(), "ts": int(Time.get_unix_time_from_system() * 1000.0), "reason": reason})
	if save_writes.size() > 200: save_writes.pop_front()
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
	var j := JSON.new()   # JSON.new().parse(): no engine error print on a corrupt save (console-zero)
	var d = j.data if j.parse(text) == OK else null
	if d is Dictionary: return d
	_backup_corrupt(text)   # SPEC §5: back up the raw string to <key>_corrupt, start fresh, no crash (TT-AC-41)
	return {}

func _backup_corrupt(text: String) -> void:
	corrupt_backed_up = true
	var k := KEY + "_corrupt"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); } catch (e) {}" % [JSON.stringify(k), JSON.stringify(text)])
	else:
		var f = FileAccess.open("user://%s.txt" % k, FileAccess.WRITE)
		if f: f.store_string(text); f.close()
