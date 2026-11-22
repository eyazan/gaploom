extends SceneTree
## Searches for force-divergent levels (baseline solves in fewer moves).
## Usage: godot --headless -s tools/find_divergent.gd -- <count> <seed> <out_dir>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[0]) if args.size() > 0 else 50000
	var base_seed := int(args[1]) if args.size() > 1 else 31337
	var out := args[2] if args.size() > 2 else "res://data/levels/divergent/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var gen := LevelGenerator.new(base_seed)
	gen.max_states = 5000  # baseline spaces explode; capped baseline = conservatively "not divergent"
	var t0 := Time.get_ticks_msec()
	var known: Dictionary = {}
	var stats := {"light": 0, "motion": 0, "mixed": 0}
	for i in count:
		var mode: String = ["light", "motion", "mixed"][i % 3]
		var res := gen.evaluate(gen.candidate(mode, base_seed + i), known, 3, true)
		if res.accepted:
			stats[mode] += 1
			var lv: LevelDefinition = res.level
			var f := FileAccess.open(out.path_join(lv.id + ".json"), FileAccess.WRITE)
			var d := lv.to_dict()
			d["baseline_min_moves"] = res.report.baseline_min_moves
			d["optimal_solutions"] = res.report.optimal_solutions
			d["states"] = res.report.states
			f.store_string(JSON.stringify(d, " "))
		if i % 2000 == 1999:
			print(i + 1, " ", stats, " ", (Time.get_ticks_msec() - t0) / 1000, "s")
	var summary := {"candidates": count, "seed": base_seed, "divergent_accepted": stats, "baseline_state_cap": 5000, "elapsed_s": (Time.get_ticks_msec() - t0) / 1000}
	var rf := FileAccess.open("res://reports/divergence_search.json", FileAccess.WRITE)
	rf.store_string(JSON.stringify(summary, " "))
	print("done ", summary)
	quit()
