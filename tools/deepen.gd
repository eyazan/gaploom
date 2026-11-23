extends SceneTree
## Solver-guided "deepening" of a handcrafted level by small local mutations (hill climbing
## with occasional sideways moves). Keeps emitters, flowers, carts, docks and mirrors fixed;
## edits only slabs, gaps and stone walls, under a clutter budget.
##
## Usage: godot --headless -s tools/deepen.gd -- <level.json> <seed> <iterations> <out.json> [min_target]
## Prints the best candidate's metrics; writes it as a level JSON (par set).

const STATE_CAP := 15000
const BASELINE_CAP := 6000
var rng := RandomNumberGenerator.new()
var base_obj_cells := 0
var base_walls := 0
var require_divergent := false


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := LevelDefinition.load_file(a[0])
	rng.seed = int(a[1])
	var iters := int(a[2])
	var out := a[3]
	var grid := _grid(src)
	base_obj_cells = _count(grid, func(t): return t[0] >= "a" and t[0] <= "z" and t[1] in ["o", "L", "M", "r", "b"])
	base_walls = _count(grid, func(t): return t == "##")
	var start := _eval(grid)
	require_divergent = start.get("divergent", false)
	if iters == 0:
		# Clean-up only (used on an already deepened file).
		var only := _simplify(grid, start)
		print("clean: ", _fmt(only[1]))
		_write(out, src, only[0], only[1])
		quit()
		return
	var cur := grid
	var cur_eval := start
	var best := grid
	var best_eval := start
	print("start: ", _fmt(start))
	for i in iters:
		var cand := _mutate(cur)
		if cand.is_empty():
			continue
		var e := _eval(cand)
		if not e.ok:
			continue
		if e.score >= cur_eval.score or rng.randf() < 0.04:
			cur = cand
			cur_eval = e
			if e.score > best_eval.score:
				best = cand
				best_eval = e
				_write(out, src, best, best_eval)  # keep progress if the run is cut short
	print("best:  ", _fmt(best_eval))
	var simple := _simplify(best, best_eval)
	best = simple[0]
	best_eval = simple[1]
	print("clean: ", _fmt(best_eval))
	_write(out, src, best, best_eval)
	quit()


## Greedy clean-up: remove walls, then single slab cells, then whole slabs, as long as the
## puzzle stays as long, at most as many optimal solutions, and keeps divergence.
func _simplify(g0: Array, e0: Dictionary) -> Array:
	var g := g0
	var e := e0
	var changed := true
	while changed:
		changed = false
		for y in g.size():
			for x in g[0].size():
				var t: String = g[y][x]
				if t == "##" or (t[0] >= "a" and t[0] <= "z" and t[1] == "o"):
					var c := _copy(g)
					c[y][x] = ".."
					var ce := _eval(c)
					if ce.ok and ce.min >= e.min and ce.opt <= e.opt and (ce.divergent or not e.divergent):
						g = c
						e = ce
						changed = true
	return [g, e]


func _write(out: String, src: LevelDefinition, g: Array, e: Dictionary) -> void:
	var d := {"format": 1, "id": src.id, "name": src.name, "world": src.world, "tutorial": src.tutorial,
		"par": e.min, "rows": _rows(g), "metrics": _fmt(e)}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, " "))


func _fmt(e: Dictionary) -> String:
	if not e.ok:
		return "invalid"
	return "min=%d base=%d opt=%d states=%d dead=%.2f div=%s score=%.2f" % [e.min, e.base, e.opt, e.states, e.dead, e.divergent, e.score]


func _grid(lv: LevelDefinition) -> Array:
	var g: Array = []
	for r in lv.to_dict().rows:
		g.append(Array(str(r).split(" ", false)))
	return g


func _rows(g: Array) -> Array:
	var out: Array = []
	for r in g:
		out.append(" ".join(PackedStringArray(r)))
	return out


func _count(g: Array, pred: Callable) -> int:
	var n := 0
	for r in g:
		for t in r:
			if pred.call(t):
				n += 1
	return n


func _copy(g: Array) -> Array:
	var c: Array = []
	for r in g:
		c.append(r.duplicate())
	return c


func _letters(g: Array) -> Array:
	var seen := {}
	for r in g:
		for t in r:
			if t[0] >= "a" and t[0] <= "z" and t[1] in ["o", "L", "M", "r", "b"]:
				seen[t[0]] = true
	return seen.keys()


func _mutate(g0: Array) -> Array:
	var g := _copy(g0)
	var h := g.size()
	var w: int = g[0].size()
	var kind := rng.randi_range(0, 6)
	var x := rng.randi_range(0, w - 1)
	var y := rng.randi_range(0, h - 1)
	var t: String = g[y][x]
	match kind:
		0, 1:  # grow a slab into an adjacent empty cell
			if t != "..":
				return []
			for d in Dir.ALL:
				var q := Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var n: String = g[q.y][q.x]
				if n[0] >= "a" and n[0] <= "z" and n[1] in ["o", "L", "M", "r", "b"]:
					g[y][x] = n[0] + "o"
					return g
			return []
		2:  # shrink a slab
			if t[0] >= "a" and t[0] <= "z" and t[1] == "o":
				g[y][x] = ".."
				return g
			return []
		3:  # solid <-> gap of the same family as an existing gap
			if t[0] >= "a" and t[0] <= "z" and t[1] == "o":
				var fams := []
				for r in g:
					for tt in r:
						if tt[1] in ["L", "M", "r", "b"]:
							fams.append(tt[1])
				if fams.is_empty():
					return []
				g[y][x] = t[0] + str(fams[rng.randi_range(0, fams.size() - 1)])
				return g
			if t[0] >= "a" and t[0] <= "z" and (t[1] in ["L", "M", "r", "b"]):
				g[y][x] = t[0] + "o"
				return g
			return []
		4:  # move a gap inside its slab (swap with a solid cell of the same slab)
			if not (t[1] in ["L", "M", "r", "b"]) or not (t[0] >= "a" and t[0] <= "z"):
				return []
			var cells := []
			for yy in h:
				for xx in w:
					var tt: String = g[yy][xx]
					if tt[0] == t[0] and tt[1] == "o":
						cells.append(Vector2i(xx, yy))
			if cells.is_empty():
				return []
			var c: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			g[c.y][c.x] = t
			g[y][x] = t[0] + "o"
			return g
		5:  # new two-cell slab with letter not yet used
			if t != "..":
				return []
			var used := _letters(g)
			var letter := ""
			for l in "abcdefghijklmnopqr":
				if not (l in used):
					letter = l
					break
			if letter == "":
				return []
			var d2: Vector2i = Dir.ALL[rng.randi_range(0, 3)]
			var q2 := Vector2i(x, y) + d2
			if q2.x < 0 or q2.y < 0 or q2.x >= w or q2.y >= h or g[q2.y][q2.x] != "..":
				return []
			g[y][x] = letter + "o"
			g[q2.y][q2.x] = letter + ("o" if rng.randf() < 0.5 else "L")
			return g
		6:  # stone wall toggle
			if t == "..":
				g[y][x] = "##"
				return g
			if t == "##":
				g[y][x] = ".."
				return g
			return []
	return []


func _eval(g: Array) -> Dictionary:
	var obj := _count(g, func(t): return t[0] >= "a" and t[0] <= "z" and t[1] in ["o", "L", "M", "r", "b"])
	var walls := _count(g, func(t): return t == "##")
	if obj > base_obj_cells + 8 or walls > base_walls + 3:
		return {"ok": false}
	var lv := LevelDefinition.from_dict({"id": "deepen", "rows": _rows(g)})
	if not lv.error.is_empty():
		return {"ok": false}
	var r := PuzzleSolver.solve(lv, STATE_CAP)
	if r.status != PuzzleSolver.STATUS_SOLVED or r.initially_solved or not r.exhaustive:
		return {"ok": false}
	# Baseline (force rule removed) only matters for the divergence term; it is capped and a capped
	# baseline counts as "not divergent" (conservative).
	TransferValidator.relaxed_frontier = true
	var b := PuzzleSolver.solve(lv, BASELINE_CAP)
	TransferValidator.relaxed_frontier = false
	var base_min: int = b.min_moves if b.status == PuzzleSolver.STATUS_SOLVED else -1
	var divergent: bool = base_min >= 0 and base_min < int(r.min_moves)
	if require_divergent and not divergent:
		return {"ok": false}
	var score: float = float(r.min_moves) * 3.0
	score -= log(maxf(1.0, float(r.optimal_solutions))) / log(2.0) * 1.2
	score += 3.0 if divergent else 0.0
	score += float(r.dead_end_ratio) * 2.0
	score -= maxf(0.0, float(obj - base_obj_cells)) * 0.25
	return {"ok": true, "score": score, "min": r.min_moves, "base": base_min, "opt": r.optimal_solutions,
		"states": r.states, "dead": r.dead_end_ratio, "divergent": divergent}
