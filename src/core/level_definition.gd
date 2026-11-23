class_name LevelDefinition
extends RefCounted
## Immutable, data-driven description of a level.
##
## Rows are written as space separated two-character tokens:
##   ..  open air              ##  fixed stone wall (never takes gaps)
##   /.  mirror '/'            \.  mirror '\'
##   E>  light emitter (dir)   R.  light receiver (bloom)
##   D.  shuttle dock          S>  shuttle (dir)     s>  solar shuttle (moves only while lit)
##   ao  object 'a' solid      aL  object 'a' light gap     aM  object 'a' motion gap
##   ar  object 'a' red glass   ab  object 'a' blue glass    Rr / Rb  red / blue flower

enum Static { EMPTY, WALL, MIRROR_SLASH, MIRROR_BACKSLASH, EMITTER, RECEIVER, DOCK }
enum Mat { NONE, SOLID, LIGHT_GAP, MOTION_GAP, LIGHT_RED, LIGHT_BLUE }
enum Hue { WHITE, RED, BLUE }

const FORMAT_VERSION := 1
const MAT_CODES := {"o": Mat.SOLID, "L": Mat.LIGHT_GAP, "M": Mat.MOTION_GAP, "r": Mat.LIGHT_RED, "b": Mat.LIGHT_BLUE}
const MAT_CHARS := {Mat.SOLID: "o", Mat.LIGHT_GAP: "L", Mat.MOTION_GAP: "M", Mat.LIGHT_RED: "r", Mat.LIGHT_BLUE: "b"}

var id := ""
var name := ""
var world := ""
var par := 0
var tutorial := ""
var width := 0
var height := 0
var error := ""

var static_cells := PackedInt32Array()
var emitter_dir: Dictionary = {}          # cell -> Vector2i
var emitters := PackedInt32Array()        # deterministic order
var receivers := PackedInt32Array()
var receiver_hue: Dictionary = {}         # cell -> Hue (WHITE = any colour)
var docks := PackedInt32Array()
var object_of := PackedInt32Array()       # cell -> object id or -1
var object_letters: Array[String] = []
var object_cells: Array[PackedInt32Array] = []
var initial_mat := PackedByteArray()
var shuttles: Array[Dictionary] = []      # {start:int, dir:Vector2i, solar:bool}


func cell_count() -> int:
	return width * height


func idx(x: int, y: int) -> int:
	return y * width + x


func idx_v(p: Vector2i) -> int:
	return p.y * width + p.x


func pos(i: int) -> Vector2i:
	return Vector2i(i % width, i / width)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func has_light() -> bool:
	return emitters.size() > 0


func has_motion() -> bool:
	return shuttles.size() > 0


static func load_file(path: String) -> LevelDefinition:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		var bad := LevelDefinition.new()
		bad.error = "cannot open %s" % path
		return bad
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		var bad2 := LevelDefinition.new()
		bad2.error = "invalid json in %s" % path
		return bad2
	return from_dict(parsed)


static func from_dict(d: Dictionary) -> LevelDefinition:
	var lv := LevelDefinition.new()
	lv.id = str(d.get("id", ""))
	lv.name = str(d.get("name", lv.id))
	lv.world = str(d.get("world", ""))
	lv.par = int(d.get("par", 0))
	lv.tutorial = str(d.get("tutorial", ""))
	var rows: Array = d.get("rows", [])
	if rows.is_empty():
		lv.error = "no rows"
		return lv
	lv.height = rows.size()
	var first: PackedStringArray = str(rows[0]).split(" ", false)
	lv.width = first.size()
	if lv.width < 2 or lv.height < 2 or lv.width > 16 or lv.height > 20:
		lv.error = "bad size %dx%d" % [lv.width, lv.height]
		return lv
	var n := lv.width * lv.height
	lv.static_cells.resize(n)
	lv.object_of.resize(n)
	lv.initial_mat.resize(n)
	lv.object_of.fill(-1)
	var letter_to_obj: Dictionary = {}
	for y in lv.height:
		var toks: PackedStringArray = str(rows[y]).split(" ", false)
		if toks.size() != lv.width:
			lv.error = "row %d has %d tokens, expected %d" % [y, toks.size(), lv.width]
			return lv
		for x in lv.width:
			var t: String = toks[x]
			var i := lv.idx(x, y)
			if t.length() != 2:
				lv.error = "bad token '%s' at %d,%d" % [t, x, y]
				return lv
			var c0 := t[0]
			var c1 := t[1]
			if t == "..":
				lv.static_cells[i] = Static.EMPTY
			elif t == "##":
				lv.static_cells[i] = Static.WALL
			elif t == "/.":
				lv.static_cells[i] = Static.MIRROR_SLASH
			elif t == "\\.":
				lv.static_cells[i] = Static.MIRROR_BACKSLASH
			elif c0 == "E" and Dir.from_char(c1) != Vector2i.ZERO:
				lv.static_cells[i] = Static.EMITTER
				lv.emitter_dir[i] = Dir.from_char(c1)
				lv.emitters.append(i)
			elif t == "R." or t == "Rr" or t == "Rb":
				lv.static_cells[i] = Static.RECEIVER
				lv.receivers.append(i)
				lv.receiver_hue[i] = Hue.WHITE if c1 == "." else (Hue.RED if c1 == "r" else Hue.BLUE)
			elif t == "D.":
				lv.static_cells[i] = Static.DOCK
				lv.docks.append(i)
			elif (c0 == "S" or c0 == "s") and Dir.from_char(c1) != Vector2i.ZERO:
				lv.static_cells[i] = Static.EMPTY
				lv.shuttles.append({"start": i, "dir": Dir.from_char(c1), "solar": c0 == "s"})
			elif c0 >= "a" and c0 <= "z" and c1 in ["o", "L", "M", "r", "b"]:
				lv.static_cells[i] = Static.EMPTY
				if not letter_to_obj.has(c0):
					letter_to_obj[c0] = lv.object_letters.size()
					lv.object_letters.append(c0)
					lv.object_cells.append(PackedInt32Array())
				var o: int = letter_to_obj[c0]
				lv.object_of[i] = o
				lv.object_cells[o].append(i)
				lv.initial_mat[i] = MAT_CODES[c1]
			else:
				lv.error = "unknown token '%s' at %d,%d" % [t, x, y]
				return lv
	lv.error = lv._validate()
	return lv


func _validate() -> String:
	if receivers.is_empty() and docks.is_empty():
		return "level has no goal"
	if docks.size() > shuttles.size():
		return "more docks than shuttles"
	if receivers.size() > 0 and emitters.is_empty():
		return "receivers without emitters"
	for o in object_cells.size():
		if not GeometryObject.is_connected_solid(self, initial_mat, o):
			return "object '%s' is not one connected piece" % object_letters[o]
	return ""


func gap_totals(mat: PackedByteArray) -> Vector2i:
	var l := 0
	var m := 0
	for v in mat:
		if v == Mat.LIGHT_GAP or v == Mat.LIGHT_RED or v == Mat.LIGHT_BLUE:
			l += 1
		elif v == Mat.MOTION_GAP:
			m += 1
	return Vector2i(l, m)


## Serializes back to the row format (used by the generator).
func to_dict() -> Dictionary:
	var rows: Array[String] = []
	var shuttle_at: Dictionary = {}
	for s in shuttles:
		shuttle_at[s.start] = s
	for y in height:
		var toks: PackedStringArray = []
		for x in width:
			var i := idx(x, y)
			var t := ".."
			if object_of[i] >= 0:
				var m := initial_mat[i]
				t = object_letters[object_of[i]] + str(MAT_CHARS[m])
			elif shuttle_at.has(i):
				var s: Dictionary = shuttle_at[i]
				t = ("s" if s.solar else "S") + Dir.to_char(s.dir)
			else:
				match static_cells[i]:
					Static.WALL:
						t = "##"
					Static.MIRROR_SLASH:
						t = "/."
					Static.MIRROR_BACKSLASH:
						t = "\\."
					Static.EMITTER:
						t = "E" + Dir.to_char(emitter_dir[i])
					Static.RECEIVER:
						t = "R" + [".", "r", "b"][int(receiver_hue.get(i, Hue.WHITE))]
					Static.DOCK:
						t = "D."
			toks.append(t)
		rows.append(" ".join(toks))
	return {"format": FORMAT_VERSION, "id": id, "name": name, "world": world, "par": par, "rows": rows}


## Canonical layout key, invariant under horizontal mirroring. Used for duplicate detection.
func canonical_key() -> String:
	var a := "|".join(to_dict().rows)
	var b := "|".join(mirrored().to_dict().rows)
	return a if a < b else b


func mirrored() -> LevelDefinition:
	var rows: Array = []
	for r in to_dict().rows:
		var toks: PackedStringArray = str(r).split(" ", false)
		toks.reverse()
		var out: PackedStringArray = []
		for t in toks:
			var c1 := t[1]
			if t == "/.":
				t = "\\."
			elif t == "\\.":
				t = "/."
			elif c1 == ">":
				t = t[0] + "<"
			elif c1 == "<":
				t = t[0] + ">"
			out.append(t)
		rows.append(" ".join(out))
	return LevelDefinition.from_dict({"id": id, "rows": rows})
