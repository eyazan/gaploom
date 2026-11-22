class_name GoalEvaluator
extends RefCounted
## Completion: every receiver is lit and every dock holds a shuttle.


static func is_solved(lv: LevelDefinition, st: BoardState, sim: Dictionary) -> bool:
	var p := progress(lv, st, sim)
	return p.x == p.y


## Vector2i(done, total) across all objectives.
static func progress(lv: LevelDefinition, st: BoardState, sim: Dictionary) -> Vector2i:
	var done := 0
	for r in lv.receivers:
		if sim.lit.has(r):
			done += 1
	for dk in lv.docks:
		if st.shuttle_at(dk) >= 0:
			done += 1
	return Vector2i(done, lv.receivers.size() + lv.docks.size())
