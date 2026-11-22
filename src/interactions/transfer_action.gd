class_name TransferAction
extends RefCounted
## Applies a validated transfer to a copy of the state and settles motion.
## Conservation is structural: one gap leaves, the same gap arrives.

const Mat = LevelDefinition.Mat

var src := -1
var dst := -1


func _init(s: int = -1, d: int = -1) -> void:
	src = s
	dst = d


## Returns {"state": BoardState, "frames": Array[PackedInt32Array]}.
static func apply(lv: LevelDefinition, st: BoardState, src_cell: int, dst_cell: int) -> Dictionary:
	var next := st.copy()
	var gap := next.mat[src_cell]
	next.mat[src_cell] = Mat.SOLID
	next.mat[dst_cell] = gap
	var frames := FunctionalSimulation.settle(lv, next)
	return {"state": next, "frames": frames}
