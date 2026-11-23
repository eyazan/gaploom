class_name Palette
extends RefCounted
## GAPLOOM visual identity: a dusk-blue miniature world lit by warm light.
## Light = warm amber circles. Motion = teal squares with rails.
## Shapes differ per family so colour is never the only cue.

const BG_TOP := Color("1b1f33")
const BG_BOTTOM := Color("2c2442")
const BOARD := Color("262b45")
const BOARD_EDGE := Color("343a5c")
const GRID_DOT := Color(1, 1, 1, 0.07)
const SOCKET := Color("161a2c")
const WALL := Color("4a4f6a")
const WALL_TOP := Color("5d6383")

const LIGHT := Color("ffd27a")
const LIGHT_CORE := Color("fff6dc")
const LIGHT_GLOW := Color(1.0, 0.78, 0.35, 0.22)
const MOTION := Color("5fe0c8")
const RED_GLASS := Color("ff6f7d")
const BLUE_GLASS := Color("6fa8ff")
const RED_CORE := Color("ffd9dd")
const BLUE_CORE := Color("dbe9ff")


## Beam colours per hue (WHITE, RED, BLUE): [glow, core].
static func hue_colors(hue: int) -> Array[Color]:
	if hue == 1:
		return [RED_GLASS, RED_CORE]
	if hue == 2:
		return [BLUE_GLASS, BLUE_CORE]
	return [LIGHT, LIGHT_CORE]
const MOTION_DARK := Color("2a8f80")

const FLOWER_OFF := Color("6e6688")
const FLOWER_ON := Color("ff8fa3")
const FLOWER_CENTER := Color("ffe08a")
const DOCK := Color("5fe0c8")
const CART := Color("ff9b7a")
const CART_DARK := Color("c96a52")
const SOLAR := Color("6fa8ff")
const MIRROR := Color("d9e1ff")

const TEXT := Color("f3ecff")
const TEXT_DIM := Color(0.95, 0.92, 1.0, 0.55)
const ACCENT := Color("ffd27a")
const DANGER := Color("ff6b6b")
const PANEL := Color(0.13, 0.14, 0.24, 0.94)
const BUTTON := Color("343a5c")
const BUTTON_HI := Color("454c75")

## Soft clay colours for slabs.
const SLABS: Array[Color] = [
	Color("e8a598"), Color("a8cbb7"), Color("c4b2e6"), Color("f0d29a"),
	Color("9cc3e4"), Color("e6b3cf"), Color("b9d38f"), Color("d9b69a"),
]


static func slab(i: int) -> Color:
	return SLABS[i % SLABS.size()]
