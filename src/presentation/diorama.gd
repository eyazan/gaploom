class_name Diorama
extends Control
## Procedural miniature world. Each completed level restores one part.
## `restored[i]` corresponds to the i-th level of the world.

var world_id := "lighthouse"
var restored: Array[bool] = []
var highlight := -1          # part index that just got restored (animated)
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, 210)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on(i: int) -> bool:
	return i < restored.size() and restored[i]


func _col(i: int, c: Color) -> Color:
	if not _on(i):
		return Color(0.55, 0.55, 0.7, 0.22)
	if i == highlight:
		return c.lerp(Color.WHITE, 0.5 * (0.5 + 0.5 * sin(_t * 8.0)))
	return c


func _draw() -> void:
	var w := size.x
	var h := size.y
	var u := minf(w / 10.0, h * 0.11)
	var base := Vector2(w * 0.5, h * 0.86)
	# ground
	var ground := PackedVector2Array([Vector2(w * 0.08, h * 0.9), Vector2(w * 0.92, h * 0.9), Vector2(w * 0.85, h * 0.98), Vector2(w * 0.15, h * 0.98)])
	draw_colored_polygon(ground, Color(1, 1, 1, 0.06))
	match world_id:
		"lighthouse":
			_lighthouse(base, u)
		"railway":
			_railway(base, u, w)
		"greenhouse":
			_greenhouse(base, u)
		"clocktower":
			_clocktower(base, u)


func _lighthouse(b: Vector2, u: float) -> void:
	# 0 rocks, 1 tower, 2 door, 3-5 windows, 6 balcony, 7 lamp room, 8 lamp, 9 beams
	for k in 5:
		draw_circle(b + Vector2((k - 2) * u * 0.9, u * 0.15), u * (0.55 + 0.1 * (k % 2)), _col(0, Color("7d7f9e")))
	var tower := PackedVector2Array([b + Vector2(-u * 1.1, 0), b + Vector2(u * 1.1, 0), b + Vector2(u * 0.75, -u * 5.2), b + Vector2(-u * 0.75, -u * 5.2)])
	draw_colored_polygon(tower, _col(1, Color("f3ece4")))
	if _on(1):
		for s in 3:
			var y := -u * (1.2 + s * 1.5)
			var hw := 1.1 - (1.2 + s * 1.5) / 5.2 * 0.35
			draw_colored_polygon(PackedVector2Array([b + Vector2(-u * hw, y), b + Vector2(u * hw, y), b + Vector2(u * (hw - 0.03), y - u * 0.5), b + Vector2(-u * (hw - 0.03), y - u * 0.5)]), Color("e8a598"))
	draw_rect(Rect2(b + Vector2(-u * 0.3, -u * 1.0), Vector2(u * 0.6, u * 1.0)), _col(2, Color("6b5a8e")))
	for k in 3:
		draw_circle(b + Vector2(0, -u * (1.9 + k * 1.1)), u * 0.2, _col(3 + k, Color("ffd27a")))
	draw_rect(Rect2(b + Vector2(-u * 1.1, -u * 5.45), Vector2(u * 2.2, u * 0.25)), _col(6, Color("c4b2e6")))
	draw_rect(Rect2(b + Vector2(-u * 0.6, -u * 6.4), Vector2(u * 1.2, u * 0.95)), _col(7, Color("9cc3e4")))
	draw_colored_polygon(PackedVector2Array([b + Vector2(-u * 0.8, -u * 6.4), b + Vector2(u * 0.8, -u * 6.4), b + Vector2(0, -u * 7.1)]), _col(7, Color("e8a598")))
	var lamp := b + Vector2(0, -u * 5.92)
	draw_circle(lamp, u * 0.3, _col(8, Color("fff6dc")))
	if _on(9):
		var sweep := sin(_t * 0.8) * 0.5
		for sd in [-1.0, 1.0]:
			var dir := Vector2(sd * cos(sweep), sin(sweep) * 0.3).normalized()
			var n := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([lamp, lamp + dir * u * 4.5 + n * u * 0.8, lamp + dir * u * 4.5 - n * u * 0.8]), Color(1, 0.85, 0.5, 0.25))
		draw_circle(lamp, u * 0.6, Color(1, 0.85, 0.5, 0.25))


func _railway(b: Vector2, u: float, w: float) -> void:
	# 0-2 track segments, 3 station, 4 train
	var y := b.y - u * 0.2
	var x0 := w * 0.12
	var seg := (w * 0.76) / 3.0
	for s in 3:
		var c := _col(s, Color("d9b69a"))
		draw_line(Vector2(x0 + seg * s, y), Vector2(x0 + seg * (s + 1), y), c, u * 0.12)
		for k in 5:
			var x := x0 + seg * s + seg * (k + 0.5) / 5.0
			draw_line(Vector2(x, y - u * 0.25), Vector2(x, y + u * 0.25), c.darkened(0.2), u * 0.12)
	var st := Vector2(w * 0.72, y - u * 0.3)
	draw_rect(Rect2(st + Vector2(-u * 1.2, -u * 2.0), Vector2(u * 2.4, u * 2.0)), _col(3, Color("a8cbb7")))
	draw_colored_polygon(PackedVector2Array([st + Vector2(-u * 1.5, -u * 2.0), st + Vector2(u * 1.5, -u * 2.0), st + Vector2(0, -u * 3.0)]), _col(3, Color("e8a598")))
	draw_rect(Rect2(st + Vector2(-u * 0.3, -u * 1.1), Vector2(u * 0.6, u * 1.1)), _col(3, Color("6b5a8e")))
	var tx := w * 0.3 + (sin(_t * 0.6) * u * 0.6 if _on(4) else 0.0)
	var tr := Vector2(tx, y - u * 0.35)
	draw_rect(Rect2(tr + Vector2(-u * 1.3, -u * 1.2), Vector2(u * 2.6, u * 1.2)), _col(4, Color("ff9b7a")))
	draw_rect(Rect2(tr + Vector2(u * 0.3, -u * 2.0), Vector2(u * 0.9, u * 0.8)), _col(4, Color("ff9b7a")))
	draw_rect(Rect2(tr + Vector2(-u * 1.0, -u * 1.8), Vector2(u * 0.35, u * 0.7)), _col(4, Color("4a4f6a")))
	for k in 3:
		draw_circle(tr + Vector2(-u * 0.9 + k * u * 0.9, 0), u * 0.3, _col(4, Color("2b2d42")))
	if _on(4):
		for k in 3:
			var p := fmod(_t * 0.5 + k * 0.33, 1.0)
			draw_circle(tr + Vector2(-u * 0.82 - p * u * 0.8, -u * (2.0 + p * 1.6)), u * (0.2 + p * 0.3), Color(1, 1, 1, 0.3 * (1.0 - p)))


func _greenhouse(b: Vector2, u: float) -> void:
	# 0 frame, 1-3 plants, 4 sun bloom
	var frame := _col(0, Color("9cc3e4"))
	var hw := u * 3.4
	var hh := u * 2.8
	var r := Rect2(b + Vector2(-hw, -hh), Vector2(hw * 2.0, hh))
	draw_rect(r, Color(frame, frame.a * 0.18))
	draw_rect(r, frame, false, 2.0)
	draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), b + Vector2(0, -hh - u * 1.6)]), Color(frame, frame.a * 0.18))
	draw_polyline(PackedVector2Array([r.position, b + Vector2(0, -hh - u * 1.6), r.position + Vector2(r.size.x, 0)]), frame, 2.0)
	for k in 3:
		draw_line(r.position + Vector2(r.size.x * (k + 1) / 4.0, 0), r.position + Vector2(r.size.x * (k + 1) / 4.0, r.size.y), Color(frame, frame.a * 0.6), 1.5)
	for k in 3:
		var px := b.x - hw * 0.6 + k * hw * 0.6
		var c := _col(1 + k, Color("b9d38f"))
		var grow := 1.0 + (0.06 * sin(_t * 2.0 + k) if _on(1 + k) else 0.0)
		draw_rect(Rect2(Vector2(px - u * 0.45, b.y - u * 0.6), Vector2(u * 0.9, u * 0.6)), _col(1 + k, Color("d9b69a")))
		draw_line(Vector2(px, b.y - u * 0.6), Vector2(px, b.y - u * 1.9 * grow), c, u * 0.12)
		draw_circle(Vector2(px - u * 0.35, b.y - u * 1.2 * grow), u * 0.3, c)
		draw_circle(Vector2(px + u * 0.35, b.y - u * 1.5 * grow), u * 0.3, c)
		draw_circle(Vector2(px, b.y - u * 2.0 * grow), u * 0.32, _col(4, Color("ff8fa3")) if _on(4) else c)
	var sun := b + Vector2(hw * 1.05, -hh - u * 1.2)
	draw_circle(sun, u * 0.55, _col(4, Color("ffd27a")))
	if _on(4):
		for k in 8:
			var a := TAU * k / 8.0 + _t * 0.4
			draw_line(sun + Vector2(cos(a), sin(a)) * u * 0.75, sun + Vector2(cos(a), sin(a)) * u * 1.05, Color("ffd27a"), 2.0)


func _clocktower(b: Vector2, u: float) -> void:
	# 0 tower, 1 clock face, 2 hands, 3 gears + bell
	var tw := u * 1.6
	var top := -u * 6.0
	draw_rect(Rect2(b + Vector2(-tw, top), Vector2(tw * 2.0, -top)), _col(0, Color("c4b2e6")))
	draw_colored_polygon(PackedVector2Array([b + Vector2(-tw * 1.2, top), b + Vector2(tw * 1.2, top), b + Vector2(0, top - u * 1.6)]), _col(0, Color("e8a598")))
	draw_rect(Rect2(b + Vector2(-u * 0.4, -u * 1.1), Vector2(u * 0.8, u * 1.1)), _col(0, Color("6b5a8e")))
	var fc := b + Vector2(0, -u * 4.2)
	draw_circle(fc, u * 1.15, _col(1, Color("fff6dc")))
	draw_arc(fc, u * 1.15, 0, TAU, 32, _col(1, Color("6b5a8e")), 3.0, true)
	for k in 12:
		var a := TAU * k / 12.0
		draw_circle(fc + Vector2(cos(a), sin(a)) * u * 0.95, u * 0.05, _col(1, Color("6b5a8e")))
	var t := _t if _on(2) else 0.0
	var ah := -PI / 2.0 + t * 0.15
	var am := -PI / 2.0 + t * 1.8
	draw_line(fc, fc + Vector2(cos(ah), sin(ah)) * u * 0.55, _col(2, Color("2b2d42")), u * 0.12)
	draw_line(fc, fc + Vector2(cos(am), sin(am)) * u * 0.85, _col(2, Color("2b2d42")), u * 0.08)
	draw_circle(fc, u * 0.1, _col(2, Color("ff9b7a")))
	var spin := _t * 0.8 if _on(3) else 0.0
	for gi in 2:
		var gc := b + Vector2((gi * 2 - 1) * tw * 1.7, -u * 1.2 - gi * u * 0.6)
		var gr := u * (0.7 - gi * 0.15)
		draw_circle(gc, gr, _col(3, Color("f0d29a")))
		for k in 8:
			var a := TAU * k / 8.0 + spin * (1.0 if gi == 0 else -1.3)
			draw_circle(gc + Vector2(cos(a), sin(a)) * gr, u * 0.16, _col(3, Color("f0d29a")))
		draw_circle(gc, gr * 0.35, _col(3, Color("d9b69a")))
	var bell := b + Vector2(0, top - u * 0.55)
	draw_colored_polygon(PackedVector2Array([bell + Vector2(-u * 0.35, u * 0.3), bell + Vector2(u * 0.35, u * 0.3), bell + Vector2(u * 0.2, -u * 0.25), bell + Vector2(-u * 0.2, -u * 0.25)]), _col(3, Color("ffd27a")))
