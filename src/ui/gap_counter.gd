class_name GapCounter
extends Control
## Shows the conserved gap inventory: light (ring) and motion (grooved square).

var counts := Vector2i.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var x := size.x
	var y := size.y * 0.5
	if counts.y > 0:
		x -= 34
		draw_string(font, Vector2(x, y + 11), str(counts.y), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.TEXT)
		x -= 26
		var r := Rect2(Vector2(x - 16, y - 16), Vector2(32, 32))
		draw_rect(r, Color(Palette.MOTION, 0.2))
		draw_rect(r, Palette.MOTION, false, 3.0)
		draw_line(Vector2(x - 9, y - 5), Vector2(x + 9, y - 5), Palette.MOTION, 3.0)
		draw_line(Vector2(x - 9, y + 5), Vector2(x + 9, y + 5), Palette.MOTION, 3.0)
		x -= 30
	if counts.x > 0:
		x -= 34
		draw_string(font, Vector2(x, y + 11), str(counts.x), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.TEXT)
		x -= 26
		draw_circle(Vector2(x, y), 22, Palette.LIGHT_GLOW)
		draw_arc(Vector2(x, y), 15, 0, TAU, 28, Palette.LIGHT, 3.5, true)
		draw_circle(Vector2(x, y), 3, Palette.LIGHT_CORE)
