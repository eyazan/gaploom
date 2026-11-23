class_name IconButton
extends Button
## Round button with a vector-drawn icon (no font or image dependency).

var icon_kind := "undo"
var tint := Palette.TEXT
var fill := Color.TRANSPARENT


func _init(kind: String = "undo", diameter: float = 96.0) -> void:
	icon_kind = kind
	custom_minimum_size = Vector2(diameter, diameter)
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var bg := Palette.BUTTON_HI if is_hovered() else Palette.BUTTON
	if fill.a > 0.0:
		bg = fill.lightened(0.1) if is_hovered() else fill
	if button_pressed or (get_draw_mode() == DRAW_PRESSED):
		bg = Palette.BUTTON_HI.lightened(0.1)
	var col := tint
	if disabled:
		bg = Color(Palette.BUTTON, 0.45)
		col = Color(tint, 0.3)
	draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.25))
	draw_circle(c, r, bg)
	var s := r * 0.42
	var w := maxf(3.0, r * 0.09)
	match icon_kind:
		"undo":
			draw_arc(c + Vector2(s * 0.1, s * 0.1), s * 0.75, PI * 1.05, PI * 2.4, 24, col, w, true)
			var tip := c + Vector2(-s * 0.65, s * 0.05)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.35, 0), tip + Vector2(s * 0.3, 0), tip + Vector2(0, -s * 0.45)]), col)
		"restart":
			draw_arc(c, s * 0.8, -PI * 0.3, PI * 1.45, 28, col, w, true)
			var tip2 := c + Vector2(cos(-PI * 0.3), sin(-PI * 0.3)) * s * 0.8
			draw_colored_polygon(PackedVector2Array([tip2 + Vector2(-s * 0.4, -s * 0.15), tip2 + Vector2(s * 0.25, -s * 0.3), tip2 + Vector2(0, s * 0.35)]), col)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(s * 0.3, -s * 0.7), c + Vector2(-s * 0.4, 0), c + Vector2(s * 0.3, s * 0.7)]), col, w, true)
		"hint":
			draw_circle(c + Vector2(0, -s * 0.2), s * 0.55, col)
			draw_rect(Rect2(c + Vector2(-s * 0.28, s * 0.35), Vector2(s * 0.56, s * 0.38)), col)
			draw_circle(c + Vector2(0, -s * 0.2), s * 0.25, bg)
		"sound_on", "sound_off":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, -s * 0.3), c + Vector2(-s * 0.35, -s * 0.3), c + Vector2(s * 0.15, -s * 0.75), c + Vector2(s * 0.15, s * 0.75), c + Vector2(-s * 0.35, s * 0.3), c + Vector2(-s * 0.8, s * 0.3)]), col)
			if icon_kind == "sound_on":
				draw_arc(c + Vector2(s * 0.2, 0), s * 0.5, -PI * 0.35, PI * 0.35, 12, col, w * 0.7, true)
				draw_arc(c + Vector2(s * 0.2, 0), s * 0.85, -PI * 0.35, PI * 0.35, 12, col, w * 0.7, true)
			else:
				draw_line(c + Vector2(s * 0.4, -s * 0.4), c + Vector2(s * 1.0, s * 0.4), col, w * 0.7, true)
				draw_line(c + Vector2(s * 1.0, -s * 0.4), c + Vector2(s * 0.4, s * 0.4), col, w * 0.7, true)
		"next":
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.7), c + Vector2(s * 0.4, 0), c + Vector2(-s * 0.3, s * 0.7)]), col, w, true)
		"music_on", "music_off":
			var nx := c + Vector2(-s * 0.35, s * 0.55)
			draw_circle(nx, s * 0.28, col)
			draw_circle(nx + Vector2(s * 0.85, -s * 0.15), s * 0.28, col)
			draw_line(nx + Vector2(s * 0.24, 0), nx + Vector2(s * 0.24, -s * 1.2), col, w * 0.8, true)
			draw_line(nx + Vector2(s * 1.09, -s * 0.15), nx + Vector2(s * 1.09, -s * 1.35), col, w * 0.8, true)
			draw_line(nx + Vector2(s * 0.24, -s * 1.2), nx + Vector2(s * 1.09, -s * 1.35), col, w, true)
			if icon_kind == "music_off":
				draw_line(c + Vector2(-s * 0.9, -s * 0.9), c + Vector2(s * 0.9, s * 0.9), Palette.DANGER, w, true)
		"help":
			draw_arc(c + Vector2(0, -s * 0.3), s * 0.42, PI * 1.0, PI * 2.35, 20, col, w, true)
			draw_line(c + Vector2(s * 0.05, -s * 0.02), c + Vector2(0, s * 0.3), col, w, true)
			draw_circle(c + Vector2(0, s * 0.72), w * 0.7, col)
		"close":
			draw_line(c + Vector2(-s * 0.6, -s * 0.6), c + Vector2(s * 0.6, s * 0.6), col, w, true)
			draw_line(c + Vector2(s * 0.6, -s * 0.6), c + Vector2(-s * 0.6, s * 0.6), col, w, true)
		"grid":
			for yy in 2:
				for xx in 2:
					draw_rect(Rect2(c + Vector2(-s * 0.7 + xx * s * 0.8, -s * 0.7 + yy * s * 0.8), Vector2(s * 0.6, s * 0.6)), col)
