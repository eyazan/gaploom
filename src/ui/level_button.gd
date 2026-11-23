class_name LevelButton
extends Button
## Level tile with number and earned stars.

var number := 1
var stars := 0
var locked := false
var perfect := false


func _init() -> void:
	custom_minimum_size = Vector2(112, 112)
	flat = true
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(26)
	sb.bg_color = Palette.BUTTON_HI if (is_hovered() and not locked) else Palette.BUTTON
	if locked:
		sb.bg_color = Color(Palette.BUTTON, 0.4)
	if stars > 0:
		sb.border_color = Color(Palette.ACCENT, 0.7)
		sb.set_border_width_all(3)
	draw_style_box(sb, r)
	var font := ThemeDB.fallback_font
	var col := Palette.TEXT if not locked else Color(Palette.TEXT, 0.3)
	draw_string(font, Vector2(0, size.y * 0.55), str(number), HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, col)
	if locked:
		var c := Vector2(size.x * 0.5, size.y * 0.78)
		draw_rect(Rect2(c - Vector2(9, 5), Vector2(18, 13)), Color(Palette.TEXT, 0.3))
		draw_arc(c - Vector2(0, 5), 6, PI, TAU, 10, Color(Palette.TEXT, 0.3), 2.5)
		return
	if perfect:
		var d := Vector2(size.x - 22, 22)
		draw_colored_polygon(PackedVector2Array([d + Vector2(0, -11), d + Vector2(9, 0), d + Vector2(0, 11), d + Vector2(-9, 0)]), Palette.ACCENT)
	for k in 3:
		var c2 := Vector2(size.x * 0.5 + (k - 1) * 22, size.y * 0.8)
		draw_circle(c2, 7, Palette.ACCENT if k < stars else Color(1, 1, 1, 0.12))
