class_name PuzzleSolver
extends RefCounted
## Deterministic breadth-first solver over canonical settled states.
##
## BFS was chosen over A*: state spaces of P0 boards are small (hundreds to a few
## thousand states), BFS gives exact optimal length and optimal-solution counts for
## free, and no admissible heuristic is obvious for the frontier-gated transfer rule.
## Search is exhaustive unless `max_states` is hit, in which case the result is
## reported as "inconclusive" (never "unsolvable").

const STATUS_SOLVED := "solved"
const STATUS_UNSOLVABLE := "unsolvable"
const STATUS_INCONCLUSIVE := "inconclusive"
const STATUS_INVALID := "invalid"


static func solve(lv: LevelDefinition, max_states: int = 200000, count_cap: int = 1000000) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	if not lv.error.is_empty():
		return {"status": STATUS_INVALID, "error": lv.error}
	var start := BoardState.initial(lv)
	FunctionalSimulation.settle(lv, start)

	var states: Array[BoardState] = [start]
	var keys: Dictionary = {start.key(): 0}
	var depth := PackedInt32Array([0])
	var paths := PackedInt64Array([1])
	var parent := PackedInt32Array([-1])
	var parent_move: Array[Vector2i] = [Vector2i(-1, -1)]
	var children: Array[PackedInt32Array] = []
	var is_goal := PackedByteArray()
	var goal_nodes := PackedInt32Array()
	var min_depth := -1
	var edges := 0
	var self_loops := 0
	var backtracks := 0
	var expanded := 0
	var exhaustive := true
	var light_moves_total := 0
	var motion_moves_total := 0

	var head := 0
	while head < states.size():
		var node := head
		head += 1
		var st: BoardState = states[node]
		var sim := FunctionalSimulation.evaluate(lv, st)
		var goal := GoalEvaluator.is_solved(lv, st, sim)
		is_goal.append(1 if goal else 0)
		children.append(PackedInt32Array())
		if goal:
			goal_nodes.append(node)
			if min_depth < 0:
				min_depth = depth[node]
			continue
		expanded += 1
		var moves := TransferValidator.legal_moves(lv, st, sim)
		for mv in moves:
			edges += 1
			if st.mat[mv.x] == LevelDefinition.Mat.LIGHT_GAP:
				light_moves_total += 1
			else:
				motion_moves_total += 1
			var res := TransferAction.apply(lv, st, mv.x, mv.y)
			var ns: BoardState = res.state
			var k := ns.key()
			if keys.has(k):
				var other: int = keys[k]
				if other == node:
					self_loops += 1
				elif depth[other] == depth[node] + 1:
					paths[other] = mini(paths[other] + paths[node], count_cap)
				else:
					backtracks += 1
				children[node].append(other)
				continue
			if states.size() >= max_states:
				exhaustive = false
				continue
			var ni := states.size()
			keys[k] = ni
			states.append(ns)
			depth.append(depth[node] + 1)
			paths.append(paths[node])
			parent.append(node)
			parent_move.append(mv)
			children[node].append(ni)

	var total := states.size()
	var result := {
		"id": lv.id,
		"states": total,
		"expanded": expanded,
		"edges": edges,
		"exhaustive": exhaustive,
		"avg_branching": (float(edges) / expanded) if expanded > 0 else 0.0,
		"self_loops": self_loops,
		"backtrack_edges": backtracks,
		"initially_solved": is_goal.size() > 0 and is_goal[0] == 1,
		"light_move_options": light_moves_total,
		"motion_move_options": motion_moves_total,
	}
	if min_depth < 0:
		result.status = STATUS_UNSOLVABLE if exhaustive else STATUS_INCONCLUSIVE
		result.min_moves = -1
		result.optimal_solutions = 0
		result.solution = []
		result.dead_end_states = total if exhaustive else -1
	else:
		result.status = STATUS_SOLVED
		result.min_moves = min_depth
		var count := 0
		var best := -1
		for g in goal_nodes:
			if depth[g] == min_depth:
				count = mini(count + paths[g], count_cap)
				if best < 0:
					best = g
		result.optimal_solutions = count
		var sol: Array = []
		var cur := best
		while parent[cur] >= 0:
			sol.push_front([parent_move[cur].x, parent_move[cur].y])
			cur = parent[cur]
		result.solution = sol
		var fam := {"light": 0, "motion": 0}
		var replay := start.copy()
		for mv in sol:
			fam[VoidProperty.family_name(VoidProperty.family_of(replay.mat[mv[0]]))] += 1
			replay = TransferAction.apply(lv, replay, mv[0], mv[1]).state
		result.solution_families = fam
		result.dead_end_states = _dead_ends(children, is_goal) if exhaustive else -1
	result.trivial = result.min_moves >= 0 and result.min_moves <= 1
	result.dead_end_ratio = (float(result.dead_end_states) / total) if (total > 0 and result.dead_end_states >= 0) else -1.0
	result.time_ms = (Time.get_ticks_usec() - t0) / 1000.0
	return result


## States from which no goal is reachable (requires an exhaustive graph).
static func _dead_ends(children: Array[PackedInt32Array], is_goal: PackedByteArray) -> int:
	var n := children.size()
	var rev: Array[PackedInt32Array] = []
	rev.resize(n)
	for i in n:
		rev[i] = PackedInt32Array()
	for i in n:
		for c in children[i]:
			rev[c].append(i)
	var good := PackedByteArray()
	good.resize(n)
	var stack: Array[int] = []
	for i in n:
		if is_goal[i] == 1:
			good[i] = 1
			stack.append(i)
	while not stack.is_empty():
		var c: int = stack.pop_back()
		for p in rev[c]:
			if good[p] == 0:
				good[p] = 1
				stack.append(p)
	var dead := 0
	for i in n:
		if good[i] == 0:
			dead += 1
	return dead
