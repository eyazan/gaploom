class_name DifficultyEstimator
extends RefCounted
## Heuristic difficulty from solver metrics. This is an engineering estimate,
## not a validated model of human difficulty; it must be calibrated with playtests.


static func score(r: Dictionary) -> float:
	if r.get("status", "") != PuzzleSolver.STATUS_SOLVED:
		return -1.0
	var s := 0.0
	s += float(r.min_moves) * 1.0
	s += log(maxf(1.0, float(r.states))) / log(2.0) * 0.35
	s += maxf(0.0, float(r.get("dead_end_ratio", 0.0))) * 3.0
	s -= log(maxf(1.0, float(r.optimal_solutions))) / log(2.0) * 0.4
	var fam: Dictionary = r.get("solution_families", {})
	if int(fam.get("light", 0)) > 0 and int(fam.get("motion", 0)) > 0:
		s += 1.0
	return snappedf(maxf(0.0, s), 0.01)


## 1 (gentle) .. 5 (hard)
static func tier(r: Dictionary) -> int:
	var s := score(r)
	if s < 0.0:
		return 0
	if s < 3.0:
		return 1
	if s < 5.0:
		return 2
	if s < 7.0:
		return 3
	if s < 9.0:
		return 4
	return 5
