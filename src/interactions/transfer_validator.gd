class_name TransferValidator
extends RefCounted
## The single rule of GAPLOOM:
##   A gap may leave any cell (its old cell becomes solid) and may only be placed
##   on a solid cell that its own force (light / motion) is currently pressing on,
##   provided every slab's solid material stays one connected piece.

const Mat = LevelDefinition.Mat

const OK := ""
const ERR_BOUNDS := "out_of_bounds"
const ERR_SAME := "same_cell"
const ERR_NO_GAP := "no_gap"
const ERR_OCCUPIED := "occupied"
const ERR_NOT_SOLID := "not_solid"
const ERR_NOT_REACHED := "not_reached"
const ERR_SPLIT := "would_split"

## Analysis-only switch: when true the frontier rule is ignored, turning the game
## into a conventional "move a hole to any solid cell" token puzzle. Used by
## tools/equivalence_check.gd to measure how much the functional rule matters.
static var relaxed_frontier := false
## Analysis-only experimental variant ("active sources"): a gap can only be taken
## from a cell its own force currently touches (light passing through it, or the
## wake of an active shuttle). Evaluated by tools/equivalence_check.gd; not used in play.
static var active_sources_only := false


static func validate(lv: LevelDefinition, st: BoardState, sim: Dictionary, src: int, dst: int) -> String:
	var n := lv.cell_count()
	if src < 0 or dst < 0 or src >= n or dst >= n:
		return ERR_BOUNDS
	if src == dst:
		return ERR_SAME
	var fam := VoidProperty.family_of(st.mat[src])
	if fam < 0:
		return ERR_NO_GAP
	if st.shuttle_at(src) >= 0:
		return ERR_OCCUPIED
	if active_sources_only:
		var touch: Dictionary = sim.light_passed if fam == VoidProperty.Family.LIGHT else sim.motion_reach
		if not touch.has(src):
			return ERR_NOT_REACHED
	if st.mat[dst] != Mat.SOLID or lv.object_of[dst] < 0:
		return ERR_NOT_SOLID
	if not relaxed_frontier and not FunctionalSimulation.frontier_for(sim, fam).has(dst):
		return ERR_NOT_REACHED
	var after := st.mat.duplicate()
	after[dst] = st.mat[src]
	after[src] = Mat.SOLID
	if not GeometryObject.is_connected_solid(lv, after, lv.object_of[dst]):
		return ERR_SPLIT
	if lv.object_of[src] != lv.object_of[dst] and not GeometryObject.is_connected_solid(lv, after, lv.object_of[src]):
		return ERR_SPLIT
	return OK


## All gap cells of the state, in cell order.
static func gap_cells(st: BoardState) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in st.mat.size():
		if st.mat[i] == Mat.LIGHT_GAP or st.mat[i] == Mat.MOTION_GAP:
			out.append(i)
	return out


## Valid destinations for one source cell (sorted).
static func destinations(lv: LevelDefinition, st: BoardState, sim: Dictionary, src: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var fam := VoidProperty.family_of(st.mat[src])
	if fam < 0:
		return out
	var keys: Array = FunctionalSimulation.frontier_for(sim, fam).keys()
	if relaxed_frontier:
		keys = []
		for i in st.mat.size():
			if st.mat[i] == Mat.SOLID:
				keys.append(i)
	keys.sort()
	for dst in keys:
		if validate(lv, st, sim, src, dst) == OK:
			out.append(dst)
	return out


## All legal moves as Vector2i(src, dst), deterministic order.
static func legal_moves(lv: LevelDefinition, st: BoardState, sim: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for src in gap_cells(st):
		for dst in destinations(lv, st, sim, src):
			out.append(Vector2i(src, dst))
	return out
