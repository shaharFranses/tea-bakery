## Renders the real in-game board (scenes/board_view.gd, shipped sprites) as a transparent PNG for the portal covers,
## so covers always match the build (portal/PORTAL_ASSET_SPECS.md: "must match the current in-game art").
## usage (needs a display, e.g. xvfb-run):
##   godot --path . --rendering-driver opengl3 -s portal/tools/render_cover_board.gd -- <out.png> [n=6] [seed=7] [px=1400] [piece=berry] [state=play]
## state "play": every cake placed, bright tiles, normal tray (the board one tap before the bake reward).
## state "solved": golden tray + solved ticks + the toasted wash; cakes keep their own colours. Steam is added by the compositor.
extends SceneTree
const BoardView = preload("res://scenes/board_view.gd")
const Gen = preload("res://game/generator.gd")
const Cells = preload("res://game/cells.gd")

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0]
	var n := int(a[1]) if a.size() > 1 else 6
	var seed_v := int(a[2]) if a.size() > 2 else 7
	var px := int(a[3]) if a.size() > 3 else 1400
	var piece: String = a[4] if a.size() > 4 else "berry"
	var state: String = a[5] if a.size() > 5 else "play"
	var vp := SubViewport.new(); vp.size = Vector2i(px, px); vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var b = BoardView.new(); vp.add_child(b)
	var m := px * 0.04
	b.position = Vector2(m, m); b.size = Vector2(px - 2 * m, px - 2 * m)
	var p: Dictionary = Gen.generate(n, seed_v)
	b.setup(n, p.regions, [], piece)
	for r in n: b.cells[r * n + int(p.solution[r])] = Cells.CAKE
	b.won = state == "solved"
	b.bake_t0 = Time.get_ticks_msec() + 1000000000   # solved tray, but never reaches the golden cake tint / steam
	b.queue_redraw()
	for i in 10: await process_frame
	vp.get_texture().get_image().save_png(out)
	var sol := []
	for r in n: sol.append(int(p.solution[r]))
	var f := FileAccess.open(out.get_basename() + ".json", FileAccess.WRITE)   # sidecar for the compositor (steam positions)
	f.store_string(JSON.stringify({"n": n, "seed": seed_v, "piece": piece, "state": state, "px": px, "margin": m, "solution": sol})); f.close()
	print("cover board: n=%d seed=%d piece=%s solution=%s -> %s" % [n, seed_v, piece, sol, out])
	quit(0)
