class_name FunctionalSimulation
extends RefCounted
## Deterministic, discrete functional simulation.
##  * Light: stateless field traced from every emitter each evaluation.
##  * Motion: stateful shuttles that advance until blocked ("settle").
## The simulation never mutates anything except during settle().

const Mat = LevelDefinition.Mat
const Static = LevelDefinition.Static


## Result of tracing every beam.
##  lit:       cell -> true for receivers and shuttle bodies hit by light
##  frontier:  cell -> true for solid object cells a beam is pressing on
##  beams:     Array[PackedVector2Array] polyline points in cell units (cell centers at integer coords)
static func trace_light(lv: LevelDefinition, st: BoardState) -> Dictionary:
	var lit: Dictionary = {}
	var frontier: Dictionary = {}
	var passed: Dictionary = {}
	var beams: Array = []
	for e in lv.emitters:
		var d: Vector2i = lv.emitter_dir[e]
		var p := lv.pos(e)
		var pts := PackedVector2Array([Vector2(p)])
		var seen: Dictionary = {}
		while true:
			var np := p + d
			if not lv.in_bounds(np):
				pts.append(Vector2(p) + Vector2(d) * 0.5)
				break
			var i := lv.idx_v(np)
			var guard := i * 4 + Dir.index_of(d)
			if seen.has(guard):
				pts.append(Vector2(np))
				break
			seen[guard] = true
			p = np
			if st.shuttle_at(i) >= 0:
				lit[i] = true
				pts.append(Vector2(np) - Vector2(d) * 0.3)
				break
			var s := lv.static_cells[i]
			if s == Static.WALL or s == Static.EMITTER:
				pts.append(Vector2(np) - Vector2(d) * 0.5)
				break
			if s == Static.RECEIVER:
				lit[i] = true
				pts.append(Vector2(np) - Vector2(d) * 0.15)
				break
			if s == Static.MIRROR_SLASH:
				pts.append(Vector2(np))
				d = Dir.reflect_slash(d)
				continue
			if s == Static.MIRROR_BACKSLASH:
				pts.append(Vector2(np))
				d = Dir.reflect_backslash(d)
				continue
			var m := st.mat[i]
			passed[i] = true
			if m == Mat.SOLID:
				frontier[i] = true
				pts.append(Vector2(np) - Vector2(d) * 0.5)
				break
			if m == Mat.MOTION_GAP:
				pts.append(Vector2(np) - Vector2(d) * 0.5)
				break
		beams.append(pts)
	return {"lit": lit, "frontier": frontier, "beams": beams, "passed": passed}


static func can_enter(lv: LevelDefinition, st: BoardState, cell: int) -> bool:
	var s := lv.static_cells[cell]
	if s != Static.EMPTY and s != Static.DOCK:
		return false
	if not VoidProperty.passes_motion(st.mat[cell]):
		return false
	return st.shuttle_at(cell) < 0


static func next_cell(lv: LevelDefinition, st: BoardState, k: int) -> int:
	var np := lv.pos(st.shuttle_cells[k]) + (lv.shuttles[k].dir as Vector2i)
	if not lv.in_bounds(np):
		return -1
	return lv.idx_v(np)


static func shuttle_active(lv: LevelDefinition, st: BoardState, k: int, lit: Dictionary) -> bool:
	if st.shuttle_docked[k] == 1:
		return false
	if lv.shuttles[k].solar and not lit.has(st.shuttle_cells[k]):
		return false
	return true


## Advances shuttles until nothing can move. Returns animation frames: the shuttle
## cells after each pass. Deterministic: shuttles are processed in index order and
## every pass uses the light field computed at the start of that pass.
static func settle(lv: LevelDefinition, st: BoardState) -> Array[PackedInt32Array]:
	var frames: Array[PackedInt32Array] = []
	if lv.shuttles.is_empty():
		return frames
	var limit := lv.cell_count() * maxi(1, lv.shuttles.size()) + 4
	for _pass in limit:
		var light := trace_light(lv, st)
		var moved := false
		for k in st.shuttle_cells.size():
			if not shuttle_active(lv, st, k, light.lit):
				continue
			var nc := next_cell(lv, st, k)
			if nc >= 0 and can_enter(lv, st, nc):
				st.shuttle_cells[k] = nc
				moved = true
				if lv.static_cells[nc] == Static.DOCK:
					st.shuttle_docked[k] = 1
		if not moved:
			break
		frames.append(st.shuttle_cells.duplicate())
	return frames


## Full derived view of a settled state.
static func evaluate(lv: LevelDefinition, st: BoardState) -> Dictionary:
	var light := trace_light(lv, st)
	var motion_frontier: Dictionary = {}
	var motion_reach: Dictionary = {}
	var active: Array[bool] = []
	for k in st.shuttle_cells.size():
		var a := shuttle_active(lv, st, k, light.lit)
		active.append(a)
		if not a:
			continue
		var nc := next_cell(lv, st, k)
		if nc >= 0 and st.mat[nc] == Mat.SOLID:
			motion_frontier[nc] = true
		# Cells directly behind an active shuttle (its wake), up to the first blocker.
		var bp := lv.pos(st.shuttle_cells[k]) - (lv.shuttles[k].dir as Vector2i)
		while lv.in_bounds(bp):
			var bi := lv.idx_v(bp)
			if not VoidProperty.passes_motion(st.mat[bi]) or (lv.static_cells[bi] != Static.EMPTY and lv.static_cells[bi] != Static.DOCK):
				break
			motion_reach[bi] = true
			bp -= (lv.shuttles[k].dir as Vector2i)
	return {
		"light_passed": light.passed,
		"motion_reach": motion_reach,
		"lit": light.lit,
		"beams": light.beams,
		"frontier_light": light.frontier,
		"frontier_motion": motion_frontier,
		"shuttle_active": active,
	}


static func frontier_for(sim: Dictionary, family: int) -> Dictionary:
	return sim.frontier_light if family == VoidProperty.Family.LIGHT else sim.frontier_motion
