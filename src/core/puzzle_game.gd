class_name PuzzleGame
extends RefCounted
## Gameplay facade: authoritative state, history (undo), restart, move counting.
## Contains no rendering or input code.

var level: LevelDefinition
var state: BoardState
var sim: Dictionary = {}
var moves := 0
var history: Array[Dictionary] = []   # {"state": BoardState, "moves": int}
var conserved := Vector2i.ZERO


func _init(lv: LevelDefinition) -> void:
	level = lv
	restart()


func restart() -> void:
	state = BoardState.initial(level)
	FunctionalSimulation.settle(level, state)
	sim = FunctionalSimulation.evaluate(level, state)
	moves = 0
	history.clear()
	conserved = level.gap_totals(state.mat)


func is_solved() -> bool:
	return GoalEvaluator.is_solved(level, state, sim)


func destinations(src: int) -> PackedInt32Array:
	return TransferValidator.destinations(level, state, sim, src)


func legal_moves() -> Array[Vector2i]:
	return TransferValidator.legal_moves(level, state, sim)


## Attempts a transfer. Invalid moves never touch the state.
## Returns {"ok": bool, "reason": String, "frames": Array, "before": BoardState}.
func try_transfer(src: int, dst: int) -> Dictionary:
	var reason := TransferValidator.validate(level, state, sim, src, dst)
	if reason != TransferValidator.OK:
		return {"ok": false, "reason": reason, "frames": [], "before": state}
	var res := TransferAction.apply(level, state, src, dst)
	history.append({"state": state, "moves": moves})
	var before := state
	state = res.state
	sim = FunctionalSimulation.evaluate(level, state)
	moves += 1
	assert(level.gap_totals(state.mat) == conserved, "gap conservation violated")
	return {"ok": true, "reason": "", "frames": res.frames, "before": before}


func can_undo() -> bool:
	return not history.is_empty()


func undo() -> bool:
	if history.is_empty():
		return false
	var h: Dictionary = history.pop_back()
	state = h.state
	moves = h.moves
	sim = FunctionalSimulation.evaluate(level, state)
	return true
