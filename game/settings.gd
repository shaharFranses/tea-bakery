## Player settings saved under save["settings"] (SPEC v1.0 §12.2, D-12, D-13). Pure logic.
extends RefCounted

const Cells = preload("res://game/cells.gd")

var tap_order: String = Cells.ORDER_MOLD_FIRST
var auto_mold := true          # D-13: ON by default

func to_dict() -> Dictionary:
	return {"tap_order": tap_order, "auto_mold": auto_mold}

func from_dict(d: Dictionary) -> void:
	var t := str(d.get("tap_order", Cells.ORDER_MOLD_FIRST))
	tap_order = t if t in [Cells.ORDER_MOLD_FIRST, Cells.ORDER_CAKE_FIRST] else Cells.ORDER_MOLD_FIRST
	auto_mold = bool(d.get("auto_mold", true))
