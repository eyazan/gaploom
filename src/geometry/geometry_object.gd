class_name GeometryObject
extends RefCounted
## Geometry rules for slabs (objects). An object's material must stay one
## 4-connected piece: a gap may never cut a slab in two.

const Mat = LevelDefinition.Mat


static func is_connected_solid(lv: LevelDefinition, mat: PackedByteArray, obj: int) -> bool:
	var cells: PackedInt32Array = lv.object_cells[obj]
	var solid: Dictionary = {}
	for c in cells:
		if mat[c] == Mat.SOLID:
			solid[c] = true
	if solid.is_empty():
		return false
	var start: int = solid.keys()[0]
	var seen: Dictionary = {start: true}
	var stack: Array[int] = [start]
	while not stack.is_empty():
		var c: int = stack.pop_back()
		var p := lv.pos(c)
		for d in Dir.ALL:
			var q := p + d
			if not lv.in_bounds(q):
				continue
			var qi := lv.idx_v(q)
			if solid.has(qi) and not seen.has(qi):
				seen[qi] = true
				stack.append(qi)
	return seen.size() == solid.size()


## Outline edges of an object, used by the renderer. Returns cells whose side `d`
## does not touch the same object.
static func is_edge(lv: LevelDefinition, cell: int, d: Vector2i) -> bool:
	var q := lv.pos(cell) + d
	if not lv.in_bounds(q):
		return true
	return lv.object_of[lv.idx_v(q)] != lv.object_of[cell]
