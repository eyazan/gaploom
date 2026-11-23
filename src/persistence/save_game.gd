class_name SaveGame
extends RefCounted
## Versioned local progress. Offline only, no account.
## Format v1: {"version":1, "levels":{id:{"done":bool,"best":int,"stars":int}}, "settings":{"sfx":bool}}

const VERSION := 1
const DEFAULT_PATH := "user://progress.json"
## Force hot-spot assist: "auto" = only in the first levels, "on" = always, "off" = never.
const ASSIST_MODES := ["auto", "on", "off"]
const ASSIST_AUTO_LAST_LEVEL := 6

var path := DEFAULT_PATH
var levels: Dictionary = {}
var settings: Dictionary = {"sfx": true, "music": true, "assist": "auto"}
var first_launch := true


static func load_from(p: String = DEFAULT_PATH) -> SaveGame:
	var s := SaveGame.new()
	s.path = p
	if not FileAccess.file_exists(p):
		return s
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return s
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("progress file corrupt, starting fresh")
		return s
	s._apply(migrate(parsed))
	s.first_launch = false
	return s


## Upgrades older formats in place. Unknown future versions are read best-effort.
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v == 0:
		# v0 (pre-release) stored {"completed": [ids]}.
		var levels: Dictionary = {}
		for id in d.get("completed", []):
			levels[str(id)] = {"done": true, "best": 0, "stars": 1}
		d = {"version": 1, "levels": levels, "settings": d.get("settings", {"sfx": true})}
	return d


func _apply(d: Dictionary) -> void:
	var lv: Variant = d.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for k in lv:
			var e: Variant = lv[k]
			if typeof(e) == TYPE_DICTIONARY:
				levels[str(k)] = {"done": bool(e.get("done", false)), "best": int(e.get("best", 0)), "stars": clampi(int(e.get("stars", 0)), 0, 3)}
	var st: Variant = d.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		settings["sfx"] = bool(st.get("sfx", true))
		settings["music"] = bool(st.get("music", true))
		var a := str(st.get("assist", "auto"))
		settings["assist"] = a if a in ASSIST_MODES else "auto"


func to_dict() -> Dictionary:
	return {"version": VERSION, "levels": levels, "settings": settings}


func save() -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	return dir.rename(tmp.get_file(), path.get_file()) == OK


func is_done(id: String) -> bool:
	return bool(levels.get(id, {}).get("done", false))


func stars(id: String) -> int:
	return int(levels.get(id, {}).get("stars", 0))


func record(id: String, moves: int, par: int) -> int:
	var s := star_rating(moves, par)
	var prev: Dictionary = levels.get(id, {"done": false, "best": 0, "stars": 0})
	var best := moves if (int(prev.best) == 0 or moves < int(prev.best)) else int(prev.best)
	levels[id] = {"done": true, "best": best, "stars": maxi(s, int(prev.stars))}
	return s


static func star_rating(moves: int, par: int) -> int:
	if par <= 0 or moves <= par:
		return 3
	if moves <= par + 2:
		return 2
	return 1


func completed_count() -> int:
	var n := 0
	for k in levels:
		if levels[k].done:
			n += 1
	return n



func hotspots_for_level(n: int) -> bool:
	match str(settings.get("assist", "auto")):
		"on":
			return true
		"off":
			return false
	return n <= ASSIST_AUTO_LAST_LEVEL
