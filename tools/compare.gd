extends SceneTree
## Solves given level files with the real rule and the conventional baseline.
## Usage: godot --headless -s tools/compare.gd -- a.json b.json ...
func _initialize() -> void:
	for p in OS.get_cmdline_user_args():
		var lv := LevelDefinition.load_file(p)
		if not lv.error.is_empty():
			print(p.get_file(), " INVALID ", lv.error)
			continue
		var a := PuzzleSolver.solve(lv)
		TransferValidator.relaxed_frontier = true
		var b := PuzzleSolver.solve(lv)
		TransferValidator.relaxed_frontier = false
		var sol := PackedStringArray()
		for mv in a.get("solution", []):
			var s: Vector2i = lv.pos(mv[0])
			var d: Vector2i = lv.pos(mv[1])
			sol.append("(%d,%d)->(%d,%d)" % [s.x, s.y, d.x, d.y])
		print("%-12s %-11s min=%d base=%d opt=%d states=%d dead=%.2f %s %s" % [p.get_file(), a.status, a.min_moves, b.min_moves, a.optimal_solutions, a.states, a.dead_end_ratio, "DIVERGENT" if (b.min_moves >= 0 and b.min_moves < a.min_moves) else "-", " ".join(sol)])
	quit()
