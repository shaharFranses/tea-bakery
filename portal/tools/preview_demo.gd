## Gameplay capture for the CrazyGames preview videos (portal/PORTAL_ASSET_SPECS.md: 15-20 s, silent, real gameplay,
## no cursor, no promo text, no speed-up). Run in Movie Maker mode so every frame is rendered at a fixed 60 fps:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 --fixed-fps 60 \
##       --write-movie <dir>/f.png -s portal/tools/preview_demo.gd -- 1.5
## Shows: level 23 (6x6) solved tap by tap (mold, then cake) -> solved card with stars -> level 24 -> chapter-end card.
## The real input path is used (main.tap_cell); nothing is faked or sped up. portal/tools/make_previews.sh cuts the mp4.
extends SceneTree
const Progress = preload("res://game/progress.gd")
const Chapters = preload("res://game/chapters.gd")

func wait(frames: int) -> void:
	for i in frames: await process_frame

func solve(m, mold_f: int, cake_f: int) -> void:
	var sol: PackedInt32Array = m.puzzle.solution
	for r in m.n:
		m.tap_cell(r, sol[r]); await wait(mold_f)     # empty -> empty mold
		m.tap_cell(r, sol[r]); await wait(cake_f)     # mold -> cake

## user args: [ui_scale=1.0] [probe]  ui_scale 1.5 at 1920x1080 lays the game out as in a 1280x720 embed (larger UI);
## "probe" quits after 1.5 s (layout check).
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	root.content_scale_factor = float(a[0]) if a.size() > 0 else 1.0
	var probe := a.size() > 1 and a[1] == "probe"
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	for c in m.get_children():
		if c.name.begins_with("PkdIntro") or c.get_class() == "CanvasLayer": c.queue_free()   # no logo intro in a preview
	m.progress = Progress.new()
	for b in range(1, Chapters.BOARDS + 1): m.progress.mark_solved("c1-b%d" % b); m.progress.record_stars("c1-b%d" % b, 3)
	m.progress.unlock_chapter(1); m.ad_policy.chapters_completed = 1
	for b in range(1, 11): m.progress.mark_solved("c2-b%d" % b); m.progress.record_stars("c2-b%d" % b, 3)
	m._on_intro_finished()
	m.open_board("c2-b11")
	await wait(36)
	if probe:
		await wait(54); quit(0); return
	await solve(m, 14, 22)
	while m.board_id() != "c2-b12" or not m.interactive: await process_frame   # bake reward + solved card, then next level
	await wait(24)
	await solve(m, 10, 14)
	while m.screen != "chapter_end": await process_frame
	await wait(330)                                    # recipe card flips in, sparkles, shine sweep, shelf drop
	quit(0)
