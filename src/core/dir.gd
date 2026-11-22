class_name Dir
extends RefCounted
## Grid direction helpers. Screen coordinates: +x right, +y down.

const RIGHT := Vector2i(1, 0)
const LEFT := Vector2i(-1, 0)
const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const ALL: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]


static func from_char(c: String) -> Vector2i:
	match c:
		">":
			return RIGHT
		"<":
			return LEFT
		"^":
			return UP
		"v":
			return DOWN
	return Vector2i.ZERO


static func to_char(d: Vector2i) -> String:
	if d == RIGHT:
		return ">"
	if d == LEFT:
		return "<"
	if d == UP:
		return "^"
	if d == DOWN:
		return "v"
	return "?"


static func index_of(d: Vector2i) -> int:
	if d == RIGHT:
		return 0
	if d == DOWN:
		return 1
	if d == LEFT:
		return 2
	return 3


## '/' mirror: a beam travelling right turns up.
static func reflect_slash(d: Vector2i) -> Vector2i:
	return Vector2i(-d.y, -d.x)


## '\' mirror: a beam travelling right turns down.
static func reflect_backslash(d: Vector2i) -> Vector2i:
	return Vector2i(d.y, d.x)
