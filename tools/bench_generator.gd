## Headless generator benchmark: godot --headless --path . -s tools/bench_generator.gd -- [seeds=200]
extends SceneTree
const Gen = preload("res://game/generator.gd")
func _init() -> void:
	var seeds := 200
	for a in OS.get_cmdline_user_args(): if a.is_valid_int(): seeds = a.to_int()
	for n in range(5, 10):
		var ms := []
		for s in seeds: ms.append(Gen.generate(n, s).ms)
		ms.sort()
		var tot := 0.0
		for m in ms: tot += m
		print("BENCH n=%d seeds=%d avg=%.1fms p50=%.1fms p95=%.1fms max=%.1fms" % [n, seeds, tot / seeds, ms[seeds / 2], ms[int(seeds * 0.95)], ms[-1]])
	quit()
