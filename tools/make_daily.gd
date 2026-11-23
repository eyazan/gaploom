extends SceneTree
## Offline daily-puzzle factory. Each puzzle is derived from a handcrafted level (optionally
## mirrored), scrambled with random edits, deepened with LevelDeepener and verified by the solver.
## Usage: godot --headless -s tools/make_daily.gd -- <first_index> <count> <stride> <out.json>
## (stride/first let several processes split the work: index = first + k*stride)

const POOL := [7, 8, 9, 10, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var first := int(a[0])
	var count := int(a[1])
	var stride := int(a[2])
	var out := a[3]
	var known: Dictionary = {}
	for p in LevelCatalog.handcrafted_paths():
		known[LevelDefinition.load_file(p).canonical_key()] = true
	var result: Array = []
	for k in count:
		var idx := first + k * stride
		var made := false
		for attempt in 6:
			var rng := RandomNumberGenerator.new()
			rng.seed = 50000 + idx * 31 + attempt * 7919
			var n: int = POOL[rng.randi_range(0, POOL.size() - 1)]
			var lv := LevelCatalog.load_level(n)
			if rng.randf() < 0.5:
				lv = lv.mirrored()
			var d := LevelDeepener.new()
			d.rng.seed = rng.seed
			d.extra_cells = 6
			d.extra_walls = 2
			d.state_cap = 4000
			d.baseline_cap = 1500
			var grid := LevelDeepener.grid_of(lv)
			d.setup(grid)
			# Scramble first so the daily is not a copy of the source level.
			var scrambled := grid
			for s in 12:
				var m := d._mutate(scrambled)
				if not m.is_empty() and d._eval(m).ok:
					scrambled = m
			var res := d.climb(scrambled, 260)
			var e: Dictionary = res[1]
			if not e.ok or e.min < 4 or e.min > 9 or e.opt > 24:
				continue
			var cand := LevelDefinition.from_dict({"id": "daily", "rows": LevelDeepener.rows_of(res[0])})
			var ck := cand.canonical_key()
			if known.has(ck):
				continue
			known[ck] = true
			result.append({"index": idx, "base": "level_%02d" % n, "par": e.min, "opt": e.opt, "states": e.states,
				"divergent": e.divergent, "rows": LevelDeepener.rows_of(res[0])})
			print("daily %d <- level_%02d  %s" % [idx, n, d.fmt(e)])
			_save(out, result)  # incremental: a killed run keeps what it made
			made = true
			break
		if not made:
			print("daily %d FAILED" % idx)
	_save(out, result)
	quit()


func _save(out: String, result: Array) -> void:
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " "))
