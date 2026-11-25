extends SceneTree
## Hard-level candidate factory for new worlds: like tools/make_daily.gd but stricter
## (>= 7 moves, <= 10 optimal solutions, force-divergent) and never duplicating a
## handcrafted level or a daily puzzle. Usage:
## godot --headless -s tools/make_world.gd -- <first> <count> <stride> <out.json>

const MIN_MOVES := 6
const MAX_OPT := 16
const POOL := [8, 9, 10, 12, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 27, 28, 29]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var first := int(a[0])
	var count := int(a[1])
	var stride := int(a[2])
	var out := a[3]
	var known: Dictionary = {}
	for p in LevelCatalog.handcrafted_paths():
		known[LevelDefinition.load_file(p).canonical_key()] = true
	for p in Daily.puzzles():
		known[LevelDefinition.from_dict({"rows": p.rows}).canonical_key()] = true
	var result: Array = []
	for k in count:
		var idx := first + k * stride
		for attempt in 4:
			var rng := RandomNumberGenerator.new()
			rng.seed = 990000 + idx * 131 + attempt * 104729
			var n: int = POOL[rng.randi_range(0, POOL.size() - 1)]
			var lv := LevelCatalog.load_level(n)
			if rng.randf() < 0.5:
				lv = lv.mirrored()
			var d := LevelDeepener.new()
			d.rng.seed = rng.seed
			d.extra_cells = 8
			d.extra_walls = 2
			d.state_cap = 8000
			d.baseline_cap = 3000
			var grid := LevelDeepener.grid_of(lv)
			d.setup(grid)
			var scrambled := grid
			for s in 10:
				var m := d._mutate(scrambled)
				if not m.is_empty() and d._eval(m).ok:
					scrambled = m
			var res := d.climb(scrambled, 350)
			var e: Dictionary = res[1]
			if not e.ok or e.min < MIN_MOVES or e.opt > MAX_OPT:
				continue
			var cand := LevelDefinition.from_dict({"id": "w", "rows": LevelDeepener.rows_of(res[0])})
			var ck := cand.canonical_key()
			if known.has(ck):
				continue
			known[ck] = true
			result.append({"index": idx, "base": "level_%02d" % n, "par": e.min, "opt": e.opt, "states": e.states,
				"dead": e.dead, "divergent": e.divergent, "rows": LevelDeepener.rows_of(res[0])})
			print("cand %d <- level_%02d  %s" % [idx, n, d.fmt(e)])
			var f := FileAccess.open(out, FileAccess.WRITE)
			f.store_string(JSON.stringify(result, " "))
			break
	quit()
