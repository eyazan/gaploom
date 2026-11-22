extends SceneTree
## Usage: godot --headless -s tools/solve_levels.gd [-- path.json ...]
## Prints solver metrics for every handcrafted level (or given files).

func _init() -> void:
	var files: Array[String] = []
	for a in OS.get_cmdline_user_args():
		files.append(a)
	if files.is_empty():
		files = LevelCatalog.handcrafted_paths()
	for f in files:
		var lv := LevelDefinition.load_file(f)
		if not lv.error.is_empty():
			print("%s  INVALID: %s" % [f.get_file(), lv.error])
			continue
		var r := PuzzleSolver.solve(lv)
		print("%-14s %-12s min=%2d opt=%4d states=%5d dead=%5.2f br=%4.1f fam=%s par=%d diff=%.2f t=%dms sol=%s" % [
			lv.id, r.status, r.min_moves, r.optimal_solutions, r.states, r.dead_end_ratio,
			r.avg_branching, str(r.get("solution_families", {})), lv.par, DifficultyEstimator.score(r), int(r.time_ms),
			_fmt(lv, r.get("solution", []))])
	quit()


func _fmt(lv: LevelDefinition, sol: Array) -> String:
	var parts: PackedStringArray = []
	for mv in sol:
		var a := lv.pos(mv[0])
		var b := lv.pos(mv[1])
		parts.append("(%d,%d)->(%d,%d)" % [a.x, a.y, b.x, b.y])
	return " ".join(parts)
