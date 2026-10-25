## Debug-hook host (lifted from sudoko_dash autoload/dbg.gd). In release this is an inert stub:
## the QA hooks live in res://debug/qa_hooks.gd, which is excluded from the release export.
extends Node

const HOOKS_PATH = "res://debug/qa_hooks.gd"
var enabled: bool = false
var clock_offset_ms: int = 0
var main = null          # the current main scene registers itself here
var hooks = null

func _ready() -> void:
	if OS.is_debug_build() and ResourceLoader.exists(HOOKS_PATH):
		hooks = load(HOOKS_PATH).new()
		enabled = true
		add_child(hooks)

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
	print("[PKD] ", msg)
	if hooks: hooks.hitlog(msg)

func publish() -> void:
	if hooks: hooks.publish()
