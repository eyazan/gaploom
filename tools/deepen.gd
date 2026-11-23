extends SceneTree
## Usage: godot --headless -s tools/deepen.gd -- <level.json> <seed> <iterations> <out.json>
## iterations = 0 runs the clean-up pass only. See src/generator/level_deepener.gd.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := LevelDefinition.load_file(a[0])
	var d := LevelDeepener.new()
	d.rng.seed = int(a[1])
	var iters := int(a[2])
	var grid := LevelDeepener.grid_of(src)
	var res: Array
	if iters == 0:
		var start := d.setup(grid)
		res = d._simplify(grid, start)
	else:
		res = d.climb(grid, iters)
	print("clean: ", d.fmt(res[1]))
	if res[1].ok:
		var out := {"format": 1, "id": src.id, "name": src.name, "world": src.world, "tutorial": src.tutorial,
			"par": res[1].min, "rows": LevelDeepener.rows_of(res[0]), "metrics": d.fmt(res[1])}
		var f := FileAccess.open(a[3], FileAccess.WRITE)
		f.store_string(JSON.stringify(out, " "))
	quit()
