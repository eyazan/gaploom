class_name BoardState
extends RefCounted
## Authoritative, discrete puzzle state. Everything else (beams, frontiers,
## goal status) is derived from it deterministically.

var mat := PackedByteArray()              # per cell material (LevelDefinition.Mat)
var shuttle_cells := PackedInt32Array()   # per shuttle cell
var shuttle_docked := PackedByteArray()   # per shuttle 0/1


static func initial(lv: LevelDefinition) -> BoardState:
	var s := BoardState.new()
	s.mat = lv.initial_mat.duplicate()
	for sh in lv.shuttles:
		s.shuttle_cells.append(sh.start)
		s.shuttle_docked.append(0)
	return s


func copy() -> BoardState:
	var s := BoardState.new()
	s.mat = mat.duplicate()
	s.shuttle_cells = shuttle_cells.duplicate()
	s.shuttle_docked = shuttle_docked.duplicate()
	return s


func shuttle_at(cell: int) -> int:
	for k in shuttle_cells.size():
		if shuttle_cells[k] == cell:
			return k
	return -1


## Canonical serialization. Gaps of the same family are indistinguishable,
## so the material grid alone already factors out gap permutations.
func key() -> String:
	var parts := PackedStringArray()
	for k in shuttle_cells.size():
		parts.append(str(shuttle_cells[k]))
	return mat.hex_encode() + "|" + ",".join(parts)


func hash_key() -> int:
	return key().hash()


func to_dict() -> Dictionary:
	return {"mat": mat.hex_encode(), "shuttles": Array(shuttle_cells), "docked": Array(shuttle_docked)}


static func from_dict(d: Dictionary) -> BoardState:
	var s := BoardState.new()
	s.mat = str(d.get("mat", "")).hex_decode()
	for v in d.get("shuttles", []):
		s.shuttle_cells.append(int(v))
	for v in d.get("docked", []):
		s.shuttle_docked.append(int(v))
	return s
