extends SceneTree
## Scans generated levels for "functional divergence": the conventional baseline
## (frontier rule off) has a strictly shorter solution, i.e. the force field itself
## forces extra reasoning. Usage: godot --headless -s tools/divergence_scan.gd -- <dir>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := args[0] if args.size() > 0 else "res://data/levels/generated/"
	var files := DirAccess.get_files_at(dir)
	var n := 0
	var div := 0
	var best: Array = []
	var variant := args.size() > 1 and args[1] == "active"
	var solvable_variant := 0
	for f in files:
		if not f.ends_with(".json"):
			continue
		var lv := LevelDefinition.load_file(dir.path_join(f))
		if not lv.error.is_empty():
			continue
		n += 1
		TransferValidator.relaxed_frontier = false
		TransferValidator.active_sources_only = variant
		var a := PuzzleSolver.solve(lv, 20000)
		TransferValidator.active_sources_only = false
		if a.status == "solved":
			solvable_variant += 1
		TransferValidator.relaxed_frontier = true
		var b := PuzzleSolver.solve(lv, 20000)
		TransferValidator.relaxed_frontier = false
		if a.status == "solved" and b.status == "solved" and b.min_moves < a.min_moves:
			div += 1
			best.append([a.min_moves - b.min_moves, a.min_moves, a.optimal_solutions, f])
	best.sort_custom(func(x, y): return x[0] > y[0] or (x[0] == y[0] and x[2] < y[2]))
	print("variant=%s scanned=%d still_solvable=%d divergent=%d (%.1f%% of solvable)" % ["active_sources" if variant else "p0", n, solvable_variant, div, 100.0 * div / maxi(1, solvable_variant)])
	for e in best.slice(0, 12):
		print(e)
	quit()
