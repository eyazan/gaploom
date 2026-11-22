extends SceneTree
## Rule-variant experiment. Generates N candidates under each rule set, then measures
## how often the conventional baseline (no force rule) has a strictly shorter
## solution ("functional divergence"). Writes reports/rule_variant_experiment.json.
## Usage: godot --headless -s tools/variant_experiment.gd -- <N> <seed>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[0]) if args.size() > 0 else 6000
	var base_seed := int(args[1]) if args.size() > 1 else 777
	var out := {}
	for variant in ["p0_frontier", "active_sources"]:
		var gen := LevelGenerator.new(base_seed)
		var known: Dictionary = {}
		var acc := 0
		var div := 0
		var gaps_sum := 0
		var min_sum := 0
		for i in count:
			var mode: String = ["light", "motion", "mixed"][i % 3]
			var d := gen.candidate(mode, base_seed + i)
			TransferValidator.active_sources_only = variant == "active_sources"
			var res := gen.evaluate(d, known)
			TransferValidator.active_sources_only = false
			if not res.accepted:
				continue
			acc += 1
			min_sum += int(res.report.min_moves)
			TransferValidator.relaxed_frontier = true
			var b := PuzzleSolver.solve(res.level, 20000)
			TransferValidator.relaxed_frontier = false
			if b.status == "solved" and b.min_moves < res.report.min_moves:
				div += 1
		out[variant] = {"candidates": count, "accepted": acc, "divergent": div,
			"divergent_share_of_accepted": snappedf(float(div) / maxi(1, acc), 0.001),
			"avg_min_moves": snappedf(float(min_sum) / maxi(1, acc), 0.01)}
		print(variant, " ", out[variant])
	var f := FileAccess.open("res://reports/rule_variant_experiment.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	quit()
