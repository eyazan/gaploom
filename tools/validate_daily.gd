extends SceneTree
## Validates data/daily/daily.json and removes bad entries (invalid, unsolved at par, < 4 moves,
## duplicate of a handcrafted level or of an earlier daily, including mirror images).
## Usage: godot --headless -s tools/validate_daily.gd [-- --dry]

func _initialize() -> void:
	var dry := OS.get_cmdline_user_args().has("--dry")
	var path := "res://data/daily/daily.json"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var keys: Dictionary = {}
	for p in LevelCatalog.handcrafted_paths():
		keys[LevelDefinition.load_file(p).canonical_key()] = "handcrafted " + p.get_file()
	var kept: Array = []
	for i in data.puzzles.size():
		var p: Dictionary = data.puzzles[i]
		var lv := LevelDefinition.from_dict({"id": "d%d" % i, "par": int(p.par), "rows": p.rows})
		var why := ""
		if not lv.error.is_empty():
			why = "invalid: " + lv.error
		else:
			var r := PuzzleSolver.solve(lv, 20000)
			if r.status != PuzzleSolver.STATUS_SOLVED:
				why = "status " + str(r.status)
			elif r.min_moves != lv.par:
				why = "par %d but optimum %d" % [lv.par, r.min_moves]
			elif r.min_moves < 4 or r.initially_solved:
				why = "too short"
			else:
				var ck := lv.canonical_key()
				if keys.has(ck):
					why = "duplicate of " + str(keys[ck])
				else:
					keys[ck] = "daily %d" % i
		if why != "":
			print("drop %d (%s): %s" % [i, p.base, why])
		else:
			kept.append(p)
	print("kept %d / %d" % [kept.size(), data.puzzles.size()])
	if not dry:
		data.puzzles = kept
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(data, " "))
	quit()
