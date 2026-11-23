class_name Daily
extends RefCounted
## Daily puzzle: everyone gets the same puzzle on the same local calendar day.
## Puzzles are pre-generated and solver-verified offline (tools/make_daily.gd) and
## shipped in data/daily/daily.json; the list cycles when it runs out.

const DATA := "res://data/daily/daily.json"
const EPOCH_UNIX := 1795392000   # 2026-11-23 00:00 UTC = daily #1
static var _cache: Array = []


static func puzzles() -> Array:
	if _cache.is_empty() and FileAccess.file_exists(DATA):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if typeof(parsed) == TYPE_DICTIONARY:
			_cache = parsed.get("puzzles", [])
	return _cache


## Day number (1-based) for a unix time, using the device's local time zone.
static func day_number(unix_time: float = -1.0) -> int:
	if unix_time < 0:
		unix_time = Time.get_unix_time_from_system()
	var bias_min: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var local := unix_time + bias_min * 60.0
	return int(floor((local - EPOCH_UNIX) / 86400.0)) + 1


static func level_for_day(day: int) -> LevelDefinition:
	var list := puzzles()
	if list.is_empty():
		var bad := LevelDefinition.new()
		bad.error = "no daily puzzles"
		return bad
	var p: Dictionary = list[posmod(day - 1, list.size())]
	var lv := LevelDefinition.from_dict({"id": "daily_%d" % day, "name": "", "world": "daily", "par": int(p.par), "rows": p.rows})
	return lv


## Shareable result text (no spoilers).
static func share_text(day: int, moves: int, par: int, stars: int, streak: int, perfect: bool) -> String:
	var s := "GAPLOOM #%d  %s\n" % [day, "★".repeat(stars) + "☆".repeat(3 - stars)]
	s += "%d / %d%s" % [moves, par, "  ◆" if perfect else ""]
	if streak > 1:
		s += "  ·  %d🔥" % streak
	s += "\nhttps://eyazan.github.io/gaploom/"
	return s
