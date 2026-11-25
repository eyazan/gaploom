extends SceneTree
## Compares every handcrafted level against a "conventional block puzzle" baseline in
## which a gap may be moved to ANY solid slab cell (frontier rule removed).
## If both variants produced the same decisions, GAPLOOM's functional rule would be
## cosmetic. Writes reports/equivalence_analysis.csv.

func _initialize() -> void:
	var rows: PackedStringArray = ["level,min_moves,min_moves_baseline,optimal_solutions,optimal_solutions_baseline,states,states_baseline,first_move_options,first_move_options_baseline,gaploom_solution_valid_in_baseline,baseline_shortcut"]
	var shortcut := 0
	var more_choices := 0
	for p in LevelCatalog.handcrafted_paths():
		var lv := LevelDefinition.load_file(p)
		TransferValidator.relaxed_frontier = false
		var a := PuzzleSolver.solve(lv)
		var ga := PuzzleGame.new(lv)
		var fa := ga.legal_moves().size()
		TransferValidator.relaxed_frontier = true
		var b := PuzzleSolver.solve(lv, 60000)   # capped: a capped baseline is reported as inconclusive
		var gb := PuzzleGame.new(lv)
		var fb := gb.legal_moves().size()
		# Every GAPLOOM move is also legal in the baseline (superset check).
		var ok := true
		for mv in a.solution:
			if not gb.try_transfer(mv[0], mv[1]).ok:
				ok = false
		TransferValidator.relaxed_frontier = false
		var sc: bool = b.status == PuzzleSolver.STATUS_SOLVED and b.min_moves < a.min_moves
		if b.status != PuzzleSolver.STATUS_SOLVED:
			print("%s baseline %s (capped search)" % [lv.id, b.status])
		if sc:
			shortcut += 1
		if fb > fa:
			more_choices += 1
		rows.append("%s,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s" % [lv.id, a.min_moves, b.min_moves, a.optimal_solutions, b.optimal_solutions, a.states, b.states, fa, fb, ok, sc])
	var f := FileAccess.open("res://reports/equivalence_analysis.csv", FileAccess.WRITE)
	f.store_string("\n".join(rows) + "\n")
	print("\n".join(rows))
	print("levels with a shorter baseline solution: %d/%d; levels with more first-move options in baseline: %d/%d" % [shortcut, LevelCatalog.COUNT, more_choices, LevelCatalog.COUNT])
	quit()
