class_name StarRow
extends Control
## Three stars; filled ones pop in.

var stars := 0:
	set(v):
		stars = v
		_t = 0.0
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		var rr := r if k % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var cx := size.x * 0.5
	for k in 3:
		var c := Vector2(cx + (k - 1) * 84, size.y * 0.5)
		_star(c, 32, Color(1, 1, 1, 0.12))
		if k < stars:
			var p := clampf((_t - 0.15 * k) / 0.3, 0.0, 1.0)
			var s := ease(p, -2.0) * (1.0 + 0.25 * sin(p * PI))
			if s > 0.01:
				_star(c, 32 * s, Palette.ACCENT)
