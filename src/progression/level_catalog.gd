class_name LevelCatalog
extends RefCounted
## Ordered list of handcrafted levels and their worlds.

const LEVEL_DIR := "res://data/levels/"
const COUNT := 37

const WORLDS := [
	{"id": "lighthouse", "first": 1, "last": 10},
	{"id": "railway", "first": 11, "last": 15},
	{"id": "greenhouse", "first": 16, "last": 20},
	{"id": "clocktower", "first": 21, "last": 24},
	{"id": "glassworks", "first": 25, "last": 29},
	{"id": "observatory", "first": 30, "last": 37},
]


static func handcrafted_paths() -> Array[String]:
	var out: Array[String] = []
	for i in range(1, COUNT + 1):
		out.append(LEVEL_DIR + "level_%02d.json" % i)
	return out


static func load_level(n: int) -> LevelDefinition:
	return LevelDefinition.load_file(LEVEL_DIR + "level_%02d.json" % n)


static func world_of(n: int) -> Dictionary:
	for w in WORLDS:
		if n >= w.first and n <= w.last:
			return w
	return WORLDS[0]
