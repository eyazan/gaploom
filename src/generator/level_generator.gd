class_name LevelGenerator
extends RefCounted
## Deterministic seeded level generator (generate-and-test).
##
## Reverse generation from solved states is NOT used: the transfer rule is not
## reversible (a destination is legal only if a force reaches it in the *current*
## state), so a reversed move sequence is not guaranteed to be playable forward.
## Instead candidates are built with path-aware heuristics and every candidate is
## validated by the exhaustive solver.

const MODE_LIGHT := "light"
const MODE_MOTION := "motion"
const MODE_MIXED := "mixed"

var rng := RandomNumberGenerator.new()
var max_states := 20000


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


## Builds one candidate. Returns {} if construction failed (counted as rejected).
func candidate(mode: String, seed_value: int) -> Dictionary:
	rng.seed = seed_value
	var w := rng.randi_range(5, 6)
	var h := rng.randi_range(5, 7)
	var grid: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append("..")
		grid.append(row)
	var rays: Array = []   # Array of Array[Vector2i] cells along a force path
	var use_light := mode != MODE_MOTION
	var use_motion := mode != MODE_LIGHT

	if use_light:
		var n_emit := rng.randi_range(1, 2)
		for _e in n_emit:
			var placed := _place_emitter(grid, w, h)
			if placed.is_empty():
				return {}
			rays.append(placed)
	if use_motion:
		var n_sh := rng.randi_range(1, 2)
		for _s in n_sh:
			var path := _place_shuttle(grid, w, h, mode == MODE_MIXED and rng.randf() < 0.35)
			if path.is_empty():
				return {}
			rays.append(path)

	# Objects, biased to sit on force paths.
	var n_obj := rng.randi_range(2, 5)
	var letters := "abcdefgh"
	var obj_cells: Array = []
	for o in n_obj:
		var seed_cell := Vector2i(-1, -1)
		if rng.randf() < 0.85 and not rays.is_empty():
			var ray: Array = rays[rng.randi_range(0, rays.size() - 1)]
			if ray.size() > 2:
				seed_cell = ray[rng.randi_range(1, ray.size() - 2)]
		if seed_cell.x < 0 or grid[seed_cell.y][seed_cell.x] != "..":
			seed_cell = _random_empty(grid, w, h)
		if seed_cell.x < 0 or grid[seed_cell.y][seed_cell.x] != "..":
			continue
		var size := rng.randi_range(2, 4)
		var cells: Array[Vector2i] = [seed_cell]
		grid[seed_cell.y][seed_cell.x] = letters[o] + "o"
		for _g in size * 3:
			if cells.size() >= size:
				break
			var base: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			var nb: Vector2i = base + Dir.ALL[rng.randi_range(0, 3)]
			if nb.x < 0 or nb.y < 0 or nb.x >= w or nb.y >= h:
				continue
			if grid[nb.y][nb.x] != "..":
				continue
			grid[nb.y][nb.x] = letters[o] + "o"
			cells.append(nb)
		obj_cells.append(cells)

	# Gaps: convert some object cells while keeping solids connected.
	var families: Array[String] = []
	if use_light:
		families.append("L")
	if use_motion:
		families.append("M")
	var n_gaps := rng.randi_range(2, 5)
	for _k in n_gaps * 4:
		if n_gaps <= 0:
			break
		if obj_cells.is_empty():
			break
		var cells: Array = obj_cells[rng.randi_range(0, obj_cells.size() - 1)]
		var c: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		var t: String = grid[c.y][c.x]
		if t[1] != "o":
			continue
		var fam: String = families[rng.randi_range(0, families.size() - 1)]
		grid[c.y][c.x] = t[0] + fam
		if not _solids_connected(grid, cells):
			grid[c.y][c.x] = t
			continue
		n_gaps -= 1

	# Optional fixed walls.
	for _wl in rng.randi_range(0, 2):
		var c := _random_empty(grid, w, h)
		if c.x >= 0:
			grid[c.y][c.x] = "##"

	var rows: Array = []
	for y in h:
		rows.append(" ".join(PackedStringArray(grid[y])))
	return {"format": LevelDefinition.FORMAT_VERSION, "id": "gen_%s_%d" % [mode, seed_value], "name": "", "world": "generated", "par": 0, "rows": rows}


func _random_empty(grid: Array, w: int, h: int) -> Vector2i:
	for _t in 40:
		var c := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		if grid[c.y][c.x] == "..":
			return c
	return Vector2i(-1, -1)


func _border_start(w: int, h: int) -> Array:
	var side := rng.randi_range(0, 3)
	match side:
		0:
			return [Vector2i(0, rng.randi_range(0, h - 1)), Dir.RIGHT]
		1:
			return [Vector2i(w - 1, rng.randi_range(0, h - 1)), Dir.LEFT]
		2:
			return [Vector2i(rng.randi_range(0, w - 1), 0), Dir.DOWN]
	return [Vector2i(rng.randi_range(0, w - 1), h - 1), Dir.UP]


## Places an emitter on the border, optionally a mirror, and a receiver along the path.
func _place_emitter(grid: Array, w: int, h: int) -> Array:
	var s: Array = _border_start(w, h)
	var p: Vector2i = s[0]
	var d: Vector2i = s[1]
	if grid[p.y][p.x] != "..":
		return []
	grid[p.y][p.x] = "E" + Dir.to_char(d)
	var path: Array = []
	var turned := false
	var cur := p
	for _step in w + h + 4:
		var nx := cur + d
		if nx.x < 0 or nx.y < 0 or nx.x >= w or nx.y >= h:
			break
		if grid[nx.y][nx.x] != "..":
			break
		cur = nx
		path.append(cur)
		if not turned and path.size() >= 2 and rng.randf() < 0.22:
			var slash := rng.randf() < 0.5
			grid[cur.y][cur.x] = "/." if slash else "\\."
			d = Dir.reflect_slash(d) if slash else Dir.reflect_backslash(d)
			turned = true
	# Receiver somewhere late on the path (not on the mirror).
	var options: Array = []
	for i in range(2, path.size()):
		var c: Vector2i = path[i]
		if grid[c.y][c.x] == "..":
			options.append(i)
	if options.is_empty():
		return []
	var ri: int = options[rng.randi_range(maxi(0, options.size() - 3), options.size() - 1)]
	var rc: Vector2i = path[ri]
	grid[rc.y][rc.x] = "R."
	return path.slice(0, ri)


func _place_shuttle(grid: Array, w: int, h: int, solar: bool) -> Array:
	var s: Array = _border_start(w, h)
	var p: Vector2i = s[0]
	var d: Vector2i = s[1]
	if grid[p.y][p.x] != "..":
		return []
	grid[p.y][p.x] = ("s" if solar else "S") + Dir.to_char(d)
	var path: Array = []
	var cur := p
	for _step in w + h:
		var nx := cur + d
		if nx.x < 0 or nx.y < 0 or nx.x >= w or nx.y >= h:
			break
		if grid[nx.y][nx.x] != "..":
			break
		cur = nx
		path.append(cur)
	if path.size() < 3:
		return []
	var di := rng.randi_range(maxi(2, path.size() - 2), path.size() - 1)
	var dc: Vector2i = path[di]
	grid[dc.y][dc.x] = "D."
	if solar:
		# A solar cart needs a light source somewhere behind it.
		var back := p - d
		if back.x >= 0 and back.y >= 0 and back.x < w and back.y < h and grid[back.y][back.x] == "..":
			grid[back.y][back.x] = "E" + Dir.to_char(d)
		else:
			grid[p.y][p.x] = "S" + Dir.to_char(d)
	return path.slice(0, di)


func _solids_connected(grid: Array, cells: Array) -> bool:
	var solid: Dictionary = {}
	for c in cells:
		if grid[c.y][c.x][1] == "o":
			solid[c] = true
	if solid.is_empty():
		return false
	var start: Vector2i = solid.keys()[0]
	var seen: Dictionary = {start: true}
	var stack: Array = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in Dir.ALL:
			var q: Vector2i = c + d
			if solid.has(q) and not seen.has(q):
				seen[q] = true
				stack.append(q)
	return seen.size() == solid.size()


## Validates one candidate dict. Returns {"accepted": bool, "reason": String, "level": LevelDefinition, "report": Dictionary}
func evaluate(d: Dictionary, known_keys: Dictionary, min_moves: int = 3, require_divergence: bool = false) -> Dictionary:
	if d.is_empty():
		return {"accepted": false, "reason": "construction_failed"}
	var lv := LevelDefinition.from_dict(d)
	if not lv.error.is_empty():
		return {"accepted": false, "reason": "invalid_definition"}
	var ck := lv.canonical_key()
	if known_keys.has(ck):
		return {"accepted": false, "reason": "duplicate"}
	known_keys[ck] = true
	var gaps := lv.gap_totals(lv.initial_mat)
	if gaps.x + gaps.y == 0:
		return {"accepted": false, "reason": "no_gaps"}
	var r := PuzzleSolver.solve(lv, max_states)
	if r.status == PuzzleSolver.STATUS_INCONCLUSIVE:
		return {"accepted": false, "reason": "inconclusive", "report": r}
	if r.status != PuzzleSolver.STATUS_SOLVED:
		return {"accepted": false, "reason": "unsolvable", "report": r}
	if r.initially_solved:
		return {"accepted": false, "reason": "initially_solved", "report": r}
	if r.min_moves < min_moves:
		return {"accepted": false, "reason": "trivial", "report": r}
	if r.optimal_solutions > 24:
		return {"accepted": false, "reason": "too_many_solutions", "report": r}
	# Every gap family present must matter: reject if a family exists but is never needed.
	var fam: Dictionary = r.solution_families
	if (gaps.x > 0 and lv.has_light() and fam.light == 0 and not lv.has_motion()) or (gaps.y > 0 and lv.has_motion() and fam.motion == 0 and not lv.has_light()):
		return {"accepted": false, "reason": "unused_family", "report": r}
	# Functional divergence: the conventional baseline (force rule removed) needs fewer moves,
	# i.e. the level cannot be solved without reasoning about where forces press.
	var baseline_min := -1
	if require_divergence:
		TransferValidator.relaxed_frontier = true
		var b := PuzzleSolver.solve(lv, max_states)
		TransferValidator.relaxed_frontier = false
		baseline_min = int(b.min_moves) if b.status == PuzzleSolver.STATUS_SOLVED else -1
		if baseline_min < 0 or baseline_min >= int(r.min_moves):
			return {"accepted": false, "reason": "not_divergent", "report": r}
	r["baseline_min_moves"] = baseline_min
	lv.par = r.min_moves
	return {"accepted": true, "reason": "", "level": lv, "report": r}
