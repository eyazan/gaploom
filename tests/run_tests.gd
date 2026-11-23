extends SceneTree
## Headless test runner (no third-party framework).
## Usage: godot --headless -s tests/run_tests.gd
## Writes reports/test_results.json and exits non-zero on failure.

const Mat = LevelDefinition.Mat

var passed := 0
var failed := 0
var failures: Array[String] = []
var suite := ""
var suite_stats: Dictionary = {}
var metrics: Dictionary = {}


func _initialize() -> void:
	_run_all()


func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		suite_stats[suite].passed += 1
	else:
		failed += 1
		suite_stats[suite].failed += 1
		failures.append("[%s] %s" % [suite, msg])
		printerr("FAIL [%s] %s" % [suite, msg])


func begin(name: String) -> void:
	suite = name
	suite_stats[name] = {"passed": 0, "failed": 0}


func _levels() -> Array[LevelDefinition]:
	var out: Array[LevelDefinition] = []
	for p in LevelCatalog.handcrafted_paths():
		out.append(LevelDefinition.load_file(p))
	return out


func _run_all() -> void:
	var t0 := Time.get_ticks_msec()
	test_parsing()
	test_light_rules()
	test_tinted_glass()
	test_motion_rules()
	test_transfer_validity()
	test_conservation_random()
	test_determinism()
	test_undo_restart()
	test_solver()
	test_solver_limits()
	test_canonical()
	test_generator()
	test_save_load()
	test_howto_pages()
	test_input_adapter()
	await test_board_view()
	test_feedback_and_assist()
	await test_music()
	await test_staged_hints()
	test_performance()
	var elapsed := Time.get_ticks_msec() - t0
	var out := {
		"engine": Engine.get_version_info().string,
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"passed": passed, "failed": failed, "elapsed_ms": elapsed,
		"suites": suite_stats, "failures": failures, "metrics": metrics,
	}
	var f := FileAccess.open("res://reports/test_results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	for s in suite_stats:
		print("%-24s passed=%-5d failed=%d" % [s, suite_stats[s].passed, suite_stats[s].failed])
	print("TOTAL passed=%d failed=%d (%d ms)" % [passed, failed, elapsed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------ suites

func test_parsing() -> void:
	begin("parsing")
	for lv in _levels():
		check(lv.error.is_empty(), "handcrafted %s parses: %s" % [lv.id, lv.error])
	var bad := [
		{"rows": []},
		{"rows": ["E> .. R.", ".. .."]},
		{"rows": ["E> ?? R.", ".. .. .."]},
		{"rows": [".. .. ..", ".. .. .."]},
		{"rows": ["E> ao .. R.", ".. .. ao .."]},
		{"rows": ["D. .. ..", ".. .. .."]},
		{"rows": ["R. .. ..", ".. .. .."]},
		{"rows": ["E> aL R.", ".. .. .."]},
	]
	for d in bad:
		var lv := LevelDefinition.from_dict(d)
		check(not lv.error.is_empty(), "invalid definition rejected: %s" % str(d.rows))
	var ok := LevelDefinition.from_dict({"rows": ["E> ao aL R.", ".. ao .. .."]})
	check(ok.error.is_empty(), "minimal valid level parses")
	var rt := LevelDefinition.from_dict(ok.to_dict())
	check(rt.error.is_empty() and rt.to_dict().rows == ok.to_dict().rows, "serialization round-trips")


func test_light_rules() -> void:
	begin("light")
	var lv := LevelDefinition.from_dict({"rows": [
		"E> .. ao .. R.",
		".. .. ao .. ..",
	]})
	var st := BoardState.initial(lv)
	var sim := FunctionalSimulation.evaluate(lv, st)
	check(sim.frontier_light.has(lv.idx(2, 0)), "beam presses on first solid cell")
	check(not sim.lit.has(lv.idx(4, 0)), "receiver dark behind solid")
	st.mat[lv.idx(2, 0)] = Mat.LIGHT_GAP
	sim = FunctionalSimulation.evaluate(lv, st)
	check(sim.lit.has(lv.idx(4, 0)), "light gap transmits light")
	st.mat[lv.idx(2, 0)] = Mat.MOTION_GAP
	sim = FunctionalSimulation.evaluate(lv, st)
	check(not sim.lit.has(lv.idx(4, 0)), "motion gap blocks light")
	check(sim.frontier_light.is_empty(), "motion gap is not a light frontier")
	var mir := LevelDefinition.from_dict({"rows": [
		"E> .. \\.",
		".. .. ..",
		"R. .. /.",
	]})
	var ms := BoardState.initial(mir)
	check(FunctionalSimulation.evaluate(mir, ms).lit.has(mir.idx(0, 2)), "mirrors route beam around two corners")
	var loop := LevelDefinition.from_dict({"rows": [
		"E> \\. .. /.",
		".. /. .. \\.",
		".. .. .. R.",
	]})
	var ls := BoardState.initial(loop)
	var lsim := FunctionalSimulation.evaluate(loop, ls)
	check(lsim.beams.size() == 1, "mirror loops terminate")


func test_motion_rules() -> void:
	begin("motion")
	var lv := LevelDefinition.from_dict({"rows": [
		"S> .. ao .. D.",
		".. bM ao .. ..",
	]})
	var g := PuzzleGame.new(lv)
	check(g.state.shuttle_cells[0] == lv.idx(1, 0), "shuttle settles against solid")
	check(g.sim.frontier_motion.has(lv.idx(2, 0)), "motion frontier in front of shuttle")
	var r := g.try_transfer(lv.idx(1, 1), lv.idx(2, 0))
	check(r.ok, "motion gap placed on frontier")
	check(g.state.shuttle_cells[0] == lv.idx(4, 0) and g.state.shuttle_docked[0] == 1, "shuttle passes groove and docks")
	check(g.is_solved(), "dock objective solved")
	check(r.frames.size() == 3, "settle produced one frame per step (%d)" % r.frames.size())
	# Gap under a shuttle cannot be taken.
	var lv2 := LevelDefinition.from_dict({"rows": [
		"S> aM ao D.",
		".. ao .. ..",
	]})
	var g2 := PuzzleGame.new(lv2)
	check(g2.state.shuttle_cells[0] == lv2.idx(1, 0), "shuttle rests inside groove")
	var moves := g2.legal_moves()
	var from_under := false
	for m in moves:
		if m.x == lv2.idx(1, 0):
			from_under = true
	check(not from_under, "gap occupied by shuttle is not a legal source")
	# Solar cart needs light.
	var sol := LevelDefinition.from_dict({"rows": [
		"E> ao s> .. D.",
		".. aL .. .. ..",
	]})
	var gs := PuzzleGame.new(sol)
	check(gs.state.shuttle_cells[0] == sol.idx(2, 0), "unlit solar cart stays")
	check(gs.try_transfer(sol.idx(1, 1), sol.idx(1, 0)).ok, "open light to the cart")
	check(gs.is_solved(), "lit solar cart rolls to dock")
	# Shuttle body casts a shadow.
	var sh := LevelDefinition.from_dict({"rows": [
		".. .. ao ao",
		"E> .. S^ R.",
		".. .. .. ..",
		"bM bo .. ..",
	]})
	var gsh := PuzzleGame.new(sh)
	check(not gsh.sim.lit.has(sh.idx(3, 1)), "cart body blocks light")
	check(gsh.try_transfer(sh.idx(0, 3), sh.idx(2, 0)).ok and gsh.is_solved(), "moving the cart lets light through")


func test_transfer_validity() -> void:
	begin("transfer_validity")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var invalid_checked := 0
	for lv in _levels():
		var g := PuzzleGame.new(lv)
		var n := lv.cell_count()
		for k in 300:
			var src := rng.randi_range(-3, n + 3)
			var dst := rng.randi_range(-3, n + 3)
			var before := g.state.key()
			var moves_before := g.moves
			var legal := g.legal_moves().has(Vector2i(src, dst))
			var r := g.try_transfer(src, dst) if not legal else {"ok": true}
			if legal:
				continue
			invalid_checked += 1
			if r.ok or g.state.key() != before or g.moves != moves_before:
				check(false, "%s invalid move (%d->%d) changed state" % [lv.id, src, dst])
				break
		check(true, "%s random invalid moves never mutate state" % lv.id)
	# Integrity: a split is rejected.
	var sp := LevelDefinition.from_dict({"rows": [
		".. ao ..",
		"E> ao R.",
		".. ao ..",
		"bL bo ..",
	]})
	var gs := PuzzleGame.new(sp)
	check(gs.try_transfer(sp.idx(0, 3), sp.idx(1, 1)).reason == TransferValidator.ERR_SPLIT, "splitting a slab is rejected")
	var fl := LevelDefinition.from_dict({"rows": [
		"E> ao .. R.",
		".. ao .. ..",
		"bo bL bL ..",
	]})
	var gf := PuzzleGame.new(fl)
	check(gf.try_transfer(fl.idx(2, 2), fl.idx(1, 0)).reason == TransferValidator.ERR_SPLIT, "creating a floating chunk at the source is rejected")
	check(gf.try_transfer(fl.idx(1, 2), fl.idx(1, 0)).ok, "inner gap first is allowed")
	metrics["invalid_moves_checked"] = invalid_checked


func _assert_invariants(lv: LevelDefinition, g: PuzzleGame, conserved: Vector2i, tag: String) -> bool:
	if lv.gap_totals(g.state.mat) != conserved:
		check(false, "%s conservation broken" % tag)
		return false
	for o in lv.object_cells.size():
		if not GeometryObject.is_connected_solid(lv, g.state.mat, o):
			check(false, "%s object %d split" % [tag, o])
			return false
	for i in lv.cell_count():
		if lv.object_of[i] < 0 and g.state.mat[i] != Mat.NONE:
			check(false, "%s material outside objects" % tag)
			return false
	var seen: Dictionary = {}
	for c in g.state.shuttle_cells:
		if seen.has(c):
			check(false, "%s two shuttles share a cell" % tag)
			return false
		seen[c] = true
		if lv.static_cells[c] != LevelDefinition.Static.EMPTY and lv.static_cells[c] != LevelDefinition.Static.DOCK:
			check(false, "%s shuttle on blocked static cell" % tag)
			return false
		if not VoidProperty.passes_motion(g.state.mat[c]):
			check(false, "%s shuttle inside solid material" % tag)
			return false
	return true


func test_conservation_random() -> void:
	begin("conservation_random")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var total_moves := 0
	for lv in _levels():
		var ok := true
		for run in 40:
			var g := PuzzleGame.new(lv)
			var conserved := g.conserved
			for step in 25:
				var moves := g.legal_moves()
				if moves.is_empty():
					break
				var mv: Vector2i = moves[rng.randi_range(0, moves.size() - 1)]
				var r := g.try_transfer(mv.x, mv.y)
				total_moves += 1
				if not r.ok:
					check(false, "%s legal move rejected" % lv.id)
					ok = false
					break
				if not _assert_invariants(lv, g, conserved, lv.id):
					ok = false
					break
			if not ok:
				break
		check(ok, "%s invariants hold over random play" % lv.id)
	metrics["random_moves_played"] = total_moves


func test_determinism() -> void:
	begin("determinism")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for lv in _levels():
		var g1 := PuzzleGame.new(lv)
		var g2 := PuzzleGame.new(lv)
		var same := g1.state.key() == g2.state.key()
		for step in 15:
			var moves := g1.legal_moves()
			if moves.is_empty():
				break
			if moves != g2.legal_moves():
				same = false
				break
			var mv: Vector2i = moves[rng.randi_range(0, moves.size() - 1)]
			var r1 := g1.try_transfer(mv.x, mv.y)
			var r2 := g2.try_transfer(mv.x, mv.y)
			if g1.state.key() != g2.state.key() or str(r1.frames) != str(r2.frames) or str(g1.sim.beams) != str(g2.sim.beams):
				same = false
				break
		check(same, "%s identical move sequences give identical states/frames/beams" % lv.id)
		var s := g1.state.copy()
		FunctionalSimulation.settle(lv, s)
		check(s.key() == g1.state.key(), "%s settled state is a fixed point" % lv.id)
		var rt := BoardState.from_dict(g1.state.to_dict())
		check(rt.key() == g1.state.key(), "%s state serialization round-trips" % lv.id)


func test_undo_restart() -> void:
	begin("undo_restart")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for lv in _levels():
		var g := PuzzleGame.new(lv)
		var initial := g.state.key()
		var keys: Array[String] = [initial]
		for step in 12:
			var moves := g.legal_moves()
			if moves.is_empty():
				break
			var mv: Vector2i = moves[rng.randi_range(0, moves.size() - 1)]
			g.try_transfer(mv.x, mv.y)
			keys.append(g.state.key())
		var ok := true
		while g.can_undo():
			keys.pop_back()
			g.undo()
			if g.state.key() != keys.back() or g.moves != keys.size() - 1:
				ok = false
				break
		check(ok and g.state.key() == initial and g.moves == 0, "%s undo walks back to the initial state" % lv.id)
		check(not g.undo(), "%s undo on empty history is a no-op" % lv.id)
		for k in 50:
			g.restart()
		check(g.state.key() == initial and g.history.is_empty(), "%s repeated restart is stable" % lv.id)


func test_solver() -> void:
	begin("solver")
	var rows: PackedStringArray = ["level,status,min_moves,par,optimal_solutions,states,expanded,edges,avg_branching,dead_end_states,dead_end_ratio,self_loops,backtrack_edges,light_moves,motion_moves,difficulty,tier,time_ms"]
	for lv in _levels():
		var r := PuzzleSolver.solve(lv)
		check(r.status == PuzzleSolver.STATUS_SOLVED, "%s solvable (%s)" % [lv.id, r.status])
		check(r.exhaustive, "%s search exhaustive" % lv.id)
		check(r.min_moves == lv.par, "%s par %d equals optimal %d" % [lv.id, lv.par, r.min_moves])
		check(not r.initially_solved, "%s not solved at start" % lv.id)
		var g := PuzzleGame.new(lv)
		var ok := true
		for mv in r.solution:
			if not g.try_transfer(mv[0], mv[1]).ok:
				ok = false
		check(ok and g.is_solved(), "%s solver solution replays to a win" % lv.id)
		var fam: Dictionary = r.get("solution_families", {})
		rows.append("%s,%s,%d,%d,%d,%d,%d,%d,%.2f,%d,%.3f,%d,%d,%d,%d,%.2f,%d,%.2f" % [lv.id, r.status, r.min_moves, lv.par, r.optimal_solutions, r.states, r.expanded, r.edges, r.avg_branching, r.dead_end_states, r.dead_end_ratio, r.self_loops, r.backtrack_edges, int(fam.get("light", 0)), int(fam.get("motion", 0)), DifficultyEstimator.score(r), DifficultyEstimator.tier(r), r.time_ms])
	var f := FileAccess.open("res://reports/solver_metrics.csv", FileAccess.WRITE)
	f.store_string("\n".join(rows) + "\n")
	f.close()
	# Hint from a mid-game state is a legal optimal first step.
	var lv7 := LevelCatalog.load_level(7)
	var g7 := PuzzleGame.new(lv7)
	var h := PuzzleSolver.hint(lv7, g7.state)
	check(g7.legal_moves().has(h), "hint is a legal move")
	# Unsolvable: two receivers but one gap.
	var un := LevelDefinition.from_dict({"rows": [
		"E> ao .. R.",
		".. ao .. ..",
		"E> bo .. R.",
		".. bo cL co",
	]})
	var ru := PuzzleSolver.solve(un)
	check(ru.status == PuzzleSolver.STATUS_UNSOLVABLE and ru.exhaustive, "insufficient gaps proven unsolvable")
	check(ru.dead_end_states == ru.states, "every state of an unsolvable level is a dead end")


func test_solver_limits() -> void:
	begin("solver_limits")
	var lv := LevelCatalog.load_level(9)
	var r := PuzzleSolver.solve(lv, 3)
	check(r.status != PuzzleSolver.STATUS_UNSOLVABLE, "state cap never reports unsolvable (got %s)" % r.status)
	check(not r.exhaustive, "state cap marks search non-exhaustive")
	var bad := LevelDefinition.from_dict({"rows": ["?? .."]})
	check(PuzzleSolver.solve(bad).status == PuzzleSolver.STATUS_INVALID, "invalid level reported as invalid")


func test_canonical() -> void:
	begin("canonical")
	for lv in _levels():
		var m := lv.mirrored()
		check(m.error.is_empty(), "%s mirror parses" % lv.id)
		check(m.canonical_key() == lv.canonical_key(), "%s mirror has same canonical key" % lv.id)
		var rm := PuzzleSolver.solve(m)
		var r := PuzzleSolver.solve(lv)
		check(rm.min_moves == r.min_moves and rm.states == r.states, "%s mirror is an equivalent puzzle" % lv.id)
	var keys: Dictionary = {}
	for lv in _levels():
		keys[lv.canonical_key()] = true
	check(keys.size() == LevelCatalog.COUNT, "no duplicate handcrafted layouts")


func test_generator() -> void:
	begin("generator")
	var g1 := LevelGenerator.new(5)
	var g2 := LevelGenerator.new(5)
	var same := true
	for i in 50:
		for mode in ["light", "motion", "mixed"]:
			if str(g1.candidate(mode, 1000 + i)) != str(g2.candidate(mode, 1000 + i)):
				same = false
	check(same, "generation is deterministic per seed")
	var known: Dictionary = {}
	var accepted := 0
	for i in 600:
		var mode: String = ["light", "motion", "mixed"][i % 3]
		var res := g1.evaluate(g1.candidate(mode, 50000 + i), known)
		if res.accepted:
			accepted += 1
			var lv: LevelDefinition = res.level
			var r: Dictionary = res.report
			check(r.status == PuzzleSolver.STATUS_SOLVED and r.min_moves >= 3, "accepted %s is solved and non-trivial" % lv.id)
			var g := PuzzleGame.new(lv)
			for mv in r.solution:
				g.try_transfer(mv[0], mv[1])
			check(g.is_solved(), "accepted %s replays" % lv.id)
	check(accepted > 0, "generator accepts some candidates (%d/600)" % accepted)
	var dup := LevelGenerator.new(1)
	var k2: Dictionary = {}
	var d := dup.candidate("motion", 777)
	var first := dup.evaluate(d, k2)
	var second := dup.evaluate(d, k2)
	check(first.reason != "duplicate" and second.reason == "duplicate", "duplicates are rejected")


func test_howto_pages() -> void:
	begin("howto")
	for i in HowTo.PAGES.size():
		var p: Dictionary = HowTo.PAGES[i]
		var lv := LevelDefinition.from_dict({"id": "howto_%d" % i, "rows": p.rows})
		check(lv.error.is_empty(), "how-to page %d board is valid (%s)" % [i, lv.error])
		var r := PuzzleSolver.solve(lv)
		check(r.status == PuzzleSolver.STATUS_SOLVED and r.min_moves >= 1, "how-to page %d demo is solvable" % i)
		check(TranslationServer.translate(p.text) != p.text or OS.has_feature("editor"), "how-to page %d text key exists" % i)


func test_save_load() -> void:
	begin("save_load")
	var path := "user://test_progress.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var s := SaveGame.load_from(path)
	check(s.first_launch and s.levels.is_empty(), "missing file gives fresh save")
	check(s.record("level_01", 1, 1) == 3, "par moves earn 3 stars")
	check(s.record("level_02", 4, 2) == 2, "par+2 earns 2 stars")
	s.record("level_03", 9, 2)
	s.settings["sfx"] = false
	check(s.save(), "save writes")
	var l := SaveGame.load_from(path)
	check(not l.first_launch, "existing file is not first launch")
	check(l.to_dict() == s.to_dict(), "save/load round-trip is lossless")
	check(l.stars("level_03") == 1 and l.is_done("level_03"), "1 star recorded")
	l.record("level_02", 2, 2)
	check(l.stars("level_02") == 3 and int(l.levels["level_02"].best) == 2, "better result upgrades record")
	l.record("level_02", 9, 2)
	check(l.stars("level_02") == 3 and int(l.levels["level_02"].best) == 2, "worse result never downgrades")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var c := SaveGame.load_from(path)
	check(c.levels.is_empty(), "corrupt file falls back to empty progress")
	var m := SaveGame.migrate({"completed": ["level_01", "level_02"]})
	check(int(m.version) == 1 and m.levels.size() == 2, "v0 migrates to v1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_input_adapter() -> void:
	begin("input_adapter")
	InputAdapter.reset()
	var t := InputEventScreenTouch.new()
	t.pressed = true
	t.position = Vector2(10, 20)
	check(InputAdapter.convert(t).kind == "press", "touch press (index 0)")
	var t2 := InputEventScreenTouch.new()
	t2.index = 1
	t2.pressed = true
	check(InputAdapter.convert(t2).is_empty(), "second finger ignored while first is down")
	var d := InputEventScreenDrag.new()
	d.position = Vector2(5, 5)
	check(InputAdapter.convert(d).kind == "move", "touch drag of primary finger")
	var up := InputEventScreenTouch.new()
	up.pressed = false
	check(InputAdapter.convert(up).kind == "release", "primary release")
	# iOS Safari: large, non-zero identifiers must still work.
	InputAdapter.reset()
	var ios := InputEventScreenTouch.new()
	ios.index = 1234567
	ios.pressed = true
	check(InputAdapter.convert(ios).kind == "press", "iOS-style touch id accepted as primary")
	var ios_d := InputEventScreenDrag.new()
	ios_d.index = 1234567
	check(InputAdapter.convert(ios_d).kind == "move", "iOS-style drag accepted")
	var ios_up := InputEventScreenTouch.new()
	ios_up.index = 1234567
	ios_up.pressed = false
	check(InputAdapter.convert(ios_up).kind == "release", "iOS-style release accepted")
	InputAdapter.reset()
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = false
	check(InputAdapter.convert(m).kind == "release", "mouse release")
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.device = InputEvent.DEVICE_ID_EMULATION
	check(InputAdapter.convert(e).is_empty(), "touch-emulated mouse ignored (no double input)")
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_RIGHT
	r.pressed = true
	check(InputAdapter.convert(r).is_empty(), "right button ignored")


func _press(view: BoardView, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	view._unhandled_input(ev)


func _drag(view: BoardView, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.position = pos
	view._unhandled_input(ev)


func test_board_view() -> void:
	begin("board_view")
	InputAdapter.reset()
	var sfx := Sfx.new()
	root.add_child(sfx)
	for size in [Vector2(720, 1280), Vector2(1080, 2400), Vector2(1280, 720), Vector2(320, 480)]:
		var lv := LevelCatalog.load_level(10)
		var g := PuzzleGame.new(lv)
		var v := BoardView.new()
		root.add_child(v)
		v.setup(g)
		v.fit(Rect2(Vector2(20, 200), size - Vector2(40, 420)))
		var board_size := Vector2(lv.width, lv.height) * v.cs
		check(v.origin.x >= 19.0 and v.origin.x + board_size.x <= size.x - 19.0, "board fits width at %s" % str(size))
		check(v.cs >= 24.0, "cells stay touchable at %s (cs=%.1f)" % [str(size), v.cs])
		v.queue_free()
	var lv1 := LevelCatalog.load_level(1)
	var game := PuzzleGame.new(lv1)
	var view := BoardView.new()
	root.add_child(view)
	view.setup(game)
	view.fit(Rect2(Vector2(0, 0), Vector2(720, 900)))
	var sol: Array = PuzzleSolver.solve(lv1).solution
	var src: int = sol[0][0]
	var dst: int = sol[0][1]
	# Drag gesture
	_press(view, view.cell_center(src), true)
	check(view.selected == src, "press selects gap")
	_drag(view, view.cell_center(dst))
	_press(view, view.cell_center(dst), false)
	check(game.moves == 1 and game.is_solved(), "drag-and-drop performs the transfer")
	await process_frame
	view.finish_animation()
	check(view.shown_mat == game.state.mat, "display synced with authoritative state after interruption")
	# Tap-tap gesture after undo
	game.undo()
	view.sync_from_game()
	_press(view, view.cell_center(src), true)
	_press(view, view.cell_center(src), false)
	check(view.selected == src, "tap keeps selection")
	_press(view, view.cell_center(dst), true)
	check(game.moves == 1, "second tap places the gap")
	_press(view, view.cell_center(dst), false)
	# Invalid drop
	game.restart()
	view.sync_from_game()
	var before := game.state.key()
	_press(view, view.cell_center(src), true)
	_drag(view, view.cell_center(0))
	_press(view, view.cell_center(0), false)
	check(game.state.key() == before and view.selected == -1, "invalid drop leaves state untouched")
	# Interrupted animations: chain transfers without waiting.
	var lv20 := LevelCatalog.load_level(20)
	var g20 := PuzzleGame.new(lv20)
	view.setup(g20)
	view.fit(Rect2(Vector2(0, 0), Vector2(720, 900)))
	for mv in PuzzleSolver.solve(lv20).solution:
		view.request_transfer(mv[0], mv[1])
		await process_frame
	view.finish_animation()
	check(g20.is_solved() and view.shown_mat == g20.state.mat, "rapid inputs during animations stay consistent")
	var vis_ok := true
	for k in g20.state.shuttle_cells.size():
		if view.shown_shuttles[k] != Vector2(lv20.pos(g20.state.shuttle_cells[k])):
			vis_ok = false
	check(vis_ok, "shuttle visuals snap to authoritative positions")
	view.queue_free()
	sfx.queue_free()


func test_performance() -> void:
	begin("performance")
	var lv := LevelCatalog.load_level(20)
	var g := PuzzleGame.new(lv)
	var n := 5000
	var t0 := Time.get_ticks_usec()
	for i in n:
		FunctionalSimulation.evaluate(lv, g.state)
	var per := float(Time.get_ticks_usec() - t0) / n
	metrics["evaluate_us"] = snappedf(per, 0.01)
	check(per < 2000.0, "simulation evaluate under 2 ms (%.1f us)" % per)
	t0 = Time.get_ticks_usec()
	var src_cell := TransferValidator.gap_cells(g.state)[0]
	for i in 200:
		g.destinations(src_cell)
	metrics["destinations_us"] = snappedf(float(Time.get_ticks_usec() - t0) / 200.0, 0.01)
	t0 = Time.get_ticks_usec()
	var total_states := 0
	for l in _levels():
		total_states += int(PuzzleSolver.solve(l).states)
	var solve_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	metrics["solve_all_handcrafted_ms"] = snappedf(solve_ms, 0.1)
	metrics["solve_all_states"] = total_states
	check(solve_ms < 5000.0, "solving all 20 levels under 5 s (%.1f ms)" % solve_ms)
	metrics["static_memory_mb"] = snappedf(OS.get_static_memory_usage() / 1048576.0, 0.01)
	metrics["static_memory_peak_mb"] = snappedf(OS.get_static_memory_peak_usage() / 1048576.0, 0.01)



func test_feedback_and_assist() -> void:
	begin("feedback_assist")
	InputAdapter.reset()
	# Split rejection marks the chunk that would break off.
	var lv4 := LevelCatalog.load_level(4)
	var g4 := PuzzleGame.new(lv4)
	var v := BoardView.new()
	v.silent = true
	root.add_child(v)
	v.setup(g4)
	v.fit(Rect2(Vector2.ZERO, Vector2(720, 900)))
	var src := lv4.idx(1, 4)
	var dst := lv4.idx(2, 1)
	_press(v, v.cell_center(src), true)
	_drag(v, v.cell_center(dst))
	_press(v, v.cell_center(dst), false)
	check(v.reject_reason == TransferValidator.ERR_SPLIT, "level 4 middle drop is a split (%s)" % v.reject_reason)
	check(v.reject_orphans.size() == 1 and (v.reject_orphans.has(lv4.idx(2, 0)) or v.reject_orphans.has(lv4.idx(2, 2))), "one broken-off chunk is highlighted (%s)" % str(v.reject_orphans))
	check(v.reject_t > 0.0, "rejection visual is active")
	check(g4.moves == 0, "rejected drop did not count as a move")
	# Not-reached rejection reveals the light hot-spots even with the assist off.
	var lv1 := LevelCatalog.load_level(1)
	var g1 := PuzzleGame.new(lv1)
	v.setup(g1)
	v.show_hotspots = false
	var gap := lv1.idx(1, 3)
	var far := lv1.idx(2, 3)
	_press(v, v.cell_center(gap), true)
	_drag(v, v.cell_center(far))
	_press(v, v.cell_center(far), false)
	check(v.reject_reason == TransferValidator.ERR_NOT_REACHED, "drop away from the light is not_reached (%s)" % v.reject_reason)
	check(v.reveal_t > 0.0 and v.reveal_family == VoidProperty.Family.LIGHT, "light hot-spots revealed after the mistake")
	v.queue_free()
	# Assist setting
	var path := "user://test_assist.json"
	var sg := SaveGame.load_from(path)
	check(str(sg.settings.assist) == "auto", "assist defaults to auto")
	check(sg.hotspots_for_level(1) and sg.hotspots_for_level(6) and not sg.hotspots_for_level(7), "auto shows hot-spots only in levels 1-6")
	sg.settings["assist"] = "off"
	sg.save()
	var sl := SaveGame.load_from(path)
	check(str(sl.settings.assist) == "off" and not sl.hotspots_for_level(1), "assist off persists and hides hot-spots")
	sl.settings["assist"] = "on"
	check(sl.hotspots_for_level(20), "assist on shows hot-spots everywhere")
	var bad := SaveGame.new()
	bad._apply({"settings": {"assist": "banana"}})
	check(str(bad.settings.assist) == "auto", "unknown assist value falls back to auto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))



func test_tinted_glass() -> void:
	begin("tinted_glass")
	var lv := LevelDefinition.from_dict({"rows": [
		"E> .. ao .. Rr",
		".. .. ao .. ..",
		"E> .. co .. Rb",
		".. .. co .. ..",
		".. gr go gb ..",
	]})
	check(lv.error.is_empty(), "red/blue glass and coloured flowers parse (%s)" % lv.error)
	check(lv.receiver_hue[lv.idx(4, 0)] == LevelDefinition.Hue.RED and lv.receiver_hue[lv.idx(4, 2)] == LevelDefinition.Hue.BLUE, "flower hues read")
	var rt := LevelDefinition.from_dict(lv.to_dict())
	check(rt.to_dict().rows == lv.to_dict().rows, "tinted tokens round-trip")
	check(lv.mirrored().canonical_key() == lv.canonical_key(), "mirror canonical key with colours")
	var g := PuzzleGame.new(lv)
	check(g.conserved == Vector2i(2, 0), "tinted glass counts as light gaps")
	# Blue glass into the red flower's beam: beam turns blue, red flower stays shut.
	check(g.try_transfer(lv.idx(3, 4), lv.idx(2, 0)).ok, "blue glass placed on a light frontier")
	check(not FunctionalSimulation.receiver_satisfied(lv, g.sim.lit_hue, lv.idx(4, 0)), "blue light does not open a red flower")
	check(g.sim.lit.has(lv.idx(4, 0)), "the flower is still hit by (blue) light")
	g.undo()
	check(g.try_transfer(lv.idx(1, 4), lv.idx(2, 0)).ok and g.try_transfer(lv.idx(3, 4), lv.idx(2, 2)).ok, "red and blue placed")
	check(g.is_solved(), "red flower by red light, blue flower by blue light")
	var hues: Array = g.sim.beam_hues
	check(hues.has(LevelDefinition.Hue.RED) and hues.has(LevelDefinition.Hue.BLUE), "beam segments carry their hues")
	# Other-hue glass blocks the beam and is not a frontier.
	var blk := LevelDefinition.from_dict({"rows": [
		"E> ar .. bb .. R.",
		".. ao .. bo .. ..",
	]})
	var gb := PuzzleGame.new(blk)
	check(not gb.sim.lit.has(blk.idx(5, 0)), "red light is stopped by blue glass")
	check(gb.sim.frontier_light.is_empty(), "blocking glass is not a placement frontier")
	check(VoidProperty.filter_hue(LevelDefinition.Mat.LIGHT_GAP, 1) == 1, "clear glass keeps hue")
	check(VoidProperty.filter_hue(LevelDefinition.Mat.LIGHT_RED, 0) == 1, "red glass tints white light")
	check(VoidProperty.filter_hue(LevelDefinition.Mat.LIGHT_RED, 2) == -1, "red glass blocks blue light")
	var r := PuzzleSolver.solve(lv)
	check(r.status == PuzzleSolver.STATUS_SOLVED and r.min_moves == 2, "solver handles colours (min=%d)" % r.min_moves)



func test_music() -> void:
	begin("music")
	var m := Music.new()
	root.add_child(m)
	for w in LevelCatalog.WORLDS:
		var st := m._stream(str(w.id))
		check(st != null, "track exists for world %s" % w.id)
		if st == null:
			continue
		var len_s := st.get_length()
		check(len_s > 15.0 and len_s < 40.0, "%s loop length %.1fs is sane" % [w.id, len_s])
		if st is AudioStreamWAV:
			check((st as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loops" % w.id)
	m.play("lighthouse")
	await process_frame
	check(m.is_playing() and m.current == "lighthouse", "music starts")
	m.play("railway")
	await create_timer(1.5).timeout
	check(m.current == "railway" and m.is_playing(), "crossfades to the next world")
	m.set_enabled(false)
	check(not m.is_playing(), "disabling stops music")
	m.set_enabled(true)
	await process_frame
	check(m.is_playing() and m.current == "railway", "re-enabling resumes the current world")
	m.queue_free()



func test_staged_hints() -> void:
	begin("staged_hints")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_level(7)
	await process_frame
	var b: BoardView = main.board
	var expected := PuzzleSolver.hint(main.game.level, main.game.state)
	main._on_hint()
	check(b.hint_src == expected.x and b.hint_move.x < 0, "first hint only marks the gap to use")
	main._on_hint()
	check(b.hint_src < 0 and b.hint_move == expected, "second hint shows the whole move")
	check(main.hints_used == 2, "hint uses are counted")
	b.request_transfer(expected.x, expected.y)
	b.finish_animation()
	check(b.hint_src < 0 and b.hint_move.x < 0, "making a move clears the hint")
	main._on_hint()
	check(b.hint_src >= 0 and b.hint_move.x < 0, "a new position starts again at stage 1")
	main.queue_free()
	var sg := SaveGame.new()
	sg.path = "user://test_perfect.json"
	sg.record("level_07", 3, 3, true)
	check(sg.is_perfect("level_07"), "par without hints is perfect")
	sg.record("level_08", 7, 7, false)
	check(not sg.is_perfect("level_08"), "using a hint is not perfect")
	sg.record("level_09", 9, 6, true)
	check(not sg.is_perfect("level_09") and sg.stars("level_09") == 1, "over par is not perfect")
	sg.record("level_07", 9, 3, false)
	check(sg.is_perfect("level_07"), "a later worse run never removes perfect")
