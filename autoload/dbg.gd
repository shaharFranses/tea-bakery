## Debug-hook host (lifted from sudoko_dash autoload/dbg.gd). In release this is an inert stub:
## the debug-only hooks live in res://debug/ (excluded from the release export); debug/boot.gd wires them up.
## Nothing in this file names a hook script, so no hook identifier ships in release (QA-A13).
extends Node

const DEBUG_BOOT = "res://debug/boot.gd"
var enabled: bool = false
var clock_offset_ms: int = 0
var main = null          # the current main scene registers itself here
var hooks = null

func _ready() -> void:
	if OS.is_debug_build() and ResourceLoader.exists(DEBUG_BOOT):
		load(DEBUG_BOOT).start(self)    # sets hooks (+ Ads mock), enabled = true

func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) + clock_offset_ms

## Toggle from the URL (?qa=1&key=value). Release builds always return the default,
## except the feature-off toggles intro=0 / audio=0, which are safe in release (boot bisecting, FF lesson).
func toggle(key: String, default_value: String = "") -> String:
	if hooks: return hooks.param(key, default_value)
	if key in ["intro", "audio"] and OS.has_feature("web"):
		var v = JavaScriptBridge.eval("new URLSearchParams(location.search).get('%s') || ''" % key)
		return str(v) if v != null and str(v) != "" else default_value
	return default_value

## Hitlog line: Dbg.hit("..."). (on-screen overlay in debug ?qa=1 builds, console always).
func hit(msg: String) -> void:
	if OS.is_debug_build(): print("[PKD] ", msg)    # release console stays clean (BR-1); hitlog is a debug tool
	if hooks: hooks.hitlog(msg)

func publish() -> void:
	if hooks: hooks.publish()
