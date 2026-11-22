extends SceneTree
## Batch generation + validation.
## Usage: godot --headless -s tools/generate_levels.gd -- <count> <base_seed> [out_dir]
## Writes reports/generation_results.json and accepted levels to data/levels/generated/.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[0]) if args.size() > 0 else 10000
	var base_seed := int(args[1]) if args.size() > 1 else 20261122
	var out_dir := args[2] if args.size() > 2 else "res://data/levels/generated/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var gen := LevelGenerator.new(base_seed)
	var known: Dictionary = {}
	# Handcrafted layouts count as known, so generated levels never duplicate them.
	for p in LevelCatalog.handcrafted_paths():
		var lv := LevelDefinition.load_file(p)
		if lv.error.is_empty():
			known[lv.canonical_key()] = true
	var reasons: Dictionary = {}
	var accepted: Array = []
	var modes := [LevelGenerator.MODE_LIGHT, LevelGenerator.MODE_MOTION, LevelGenerator.MODE_MIXED]
	var per_mode: Dictionary = {}
	var t0 := Time.get_ticks_msec()
	var min_hist: Dictionary = {}
	var states_total := 0
	for i in count:
		var mode: String = modes[i % 3]
		var seed_value := base_seed + i
		var d := gen.candidate(mode, seed_value)
		var res := gen.evaluate(d, known)
		var pm: Dictionary = per_mode.get(mode, {"candidates": 0, "accepted": 0})
		pm.candidates += 1
		if res.has("report"):
			states_total += int(res.report.states)
		if res.accepted:
			pm.accepted += 1
			var lv: LevelDefinition = res.level
			var r: Dictionary = res.report
			min_hist[str(r.min_moves)] = int(min_hist.get(str(r.min_moves), 0)) + 1
			accepted.append({"id": lv.id, "mode": mode, "seed": seed_value, "min_moves": r.min_moves,
				"optimal_solutions": r.optimal_solutions, "states": r.states, "dead_end_ratio": snappedf(r.dead_end_ratio, 0.001),
				"families": r.solution_families, "difficulty": DifficultyEstimator.score(r), "tier": DifficultyEstimator.tier(r)})
			var f := FileAccess.open(out_dir.path_join(lv.id + ".json"), FileAccess.WRITE)
			f.store_string(JSON.stringify(lv.to_dict(), " "))
		else:
			reasons[res.reason] = int(reasons.get(res.reason, 0)) + 1
		per_mode[mode] = pm
		if i % 1000 == 999:
			print("  %d / %d candidates, %d accepted" % [i + 1, count, accepted.size()])
	var elapsed := Time.get_ticks_msec() - t0
	var summary := {
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"engine": Engine.get_version_info().string,
		"base_seed": base_seed,
		"candidates": count,
		"accepted": accepted.size(),
		"acceptance_rate": snappedf(float(accepted.size()) / maxf(1.0, count), 0.0001),
		"rejections": reasons,
		"per_mode": per_mode,
		"min_moves_histogram": min_hist,
		"solver_states_total": states_total,
		"elapsed_ms": elapsed,
		"accepted_levels": accepted,
	}
	var rf := FileAccess.open("res://reports/generation_results.json", FileAccess.WRITE)
	rf.store_string(JSON.stringify(summary, " "))
	print("candidates=%d accepted=%d rate=%.4f elapsed=%dms" % [count, accepted.size(), summary.acceptance_rate, elapsed])
	print("rejections=", reasons)
	print("per_mode=", per_mode)
	print("min_moves=", min_hist)
	quit()
