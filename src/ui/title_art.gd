class_name TitleArt
extends Control
## Animated title illustration that demonstrates the core rule in 3 seconds:
## a glass gap leaves its slot (which turns solid), lands where the light presses,
## the beam passes through and the flower blooms.

const LOOP := 3.4
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _cell(c: Vector2, u: float, col: Color) -> void:
	var r := Rect2(c - Vector2(u, u) * 0.47, Vector2(u, u) * 0.94)
	draw_rect(Rect2(r.position + Vector2(0, u * 0.07), r.size), col.darkened(0.42))
	draw_rect(r, col)


func _socket(c: Vector2, u: float) -> void:
	draw_rect(Rect2(c - Vector2(u, u) * 0.38, Vector2(u, u) * 0.76), Palette.SOCKET)


func _token(c: Vector2, u: float, a: float) -> void:
	draw_circle(c, u * 0.42, Color(Palette.LIGHT_GLOW, Palette.LIGHT_GLOW.a * a))
	draw_arc(c, u * 0.28, 0, TAU, 32, Color(Palette.LIGHT, a), 4.0, true)
	draw_circle(c, u * 0.05, Color(Palette.LIGHT_CORE, a))


func _draw() -> void:
	var w := size.x
	var u := minf(w / 6.5, 104.0)
	var cy := size.y * 0.2
	var t := fmod(_t, LOOP)
	var fly := clampf((t - 0.7) / 0.5, 0.0, 1.0)
	var flown := fly >= 1.0
	var bloom := clampf((t - 1.35) / 0.5, 0.0, 1.0) * clampf((LOOP - t) / 0.3, 0.0, 1.0)
	var slab_x := w * 0.5
	var src := Vector2(slab_x, cy + u)          # lower slot holds the gap at first
	var dst := Vector2(slab_x, cy)              # beam row
	var em := Vector2(w * 0.5 - u * 2.3, cy)
	var fl := Vector2(w * 0.5 + u * 2.3, cy)
	# slab: three cells in a column plus a foot
	for k in [-1, 0, 1]:
		var c := Vector2(slab_x, cy + k * u)
		if (k == 0 and flown) or (k == 1 and fly < 0.55):
			_socket_or_cell(c, u, k, flown, fly)
		else:
			_cell(c, u, Palette.slab(0))
	_cell(Vector2(slab_x + u, cy + u), u, Palette.slab(0))
	# beam
	var end := dst - Vector2(u * 0.5, 0)
	if flown:
		end = fl - Vector2(u * 0.2, 0)
	draw_line(em, end, Color(Palette.LIGHT, 0.15), u * 0.42)
	draw_line(em, end, Color(Palette.LIGHT, 0.45), u * 0.15)
	draw_line(em, end, Palette.LIGHT_CORE, 3.0)
	if not flown:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		draw_circle(end, u * (0.13 + 0.06 * pulse), Color(Palette.LIGHT, 0.6))
	draw_circle(em, u * 0.34, Color("6b5a8e"))
	draw_circle(em, u * 0.22, Palette.LIGHT)
	# flower
	draw_line(fl + Vector2(0, u * 0.1), fl + Vector2(0, u * 0.45), Color("6fbf8a"), 4.0)
	var col := Palette.FLOWER_OFF.lerp(Palette.FLOWER_ON, bloom)
	if bloom > 0.0:
		draw_circle(fl, u * 0.55 * bloom, Color(Palette.FLOWER_ON, 0.18))
	for k in 6:
		var a := TAU * k / 6.0
		draw_circle(fl + Vector2(cos(a), sin(a)) * u * (0.07 + 0.15 * bloom), u * (0.1 + 0.06 * bloom), col)
	draw_circle(fl, u * 0.1, Palette.FLOWER_CENTER if bloom > 0.5 else Palette.FLOWER_OFF.darkened(0.2))
	# token
	if fly <= 0.0:
		_token(src, u, 1.0)
	elif not flown:
		var e := ease(fly, -2.0)
		_token(src.lerp(dst, e) + Vector2(-u * 0.5 * sin(e * PI), 0), u, 1.0)
	else:
		_token(dst, u, 1.0)


func _socket_or_cell(c: Vector2, u: float, k: int, flown: bool, fly: float) -> void:
	# k == 0: beam slot, open after the gap lands. k == 1: source slot, open until the gap leaves.
	if k == 0 and flown:
		draw_rect(Rect2(c - Vector2(u, u) * 0.47, Vector2(u, u) * 0.94), Palette.BOARD)
		_socket(c, u)
	elif k == 1:
		draw_rect(Rect2(c - Vector2(u, u) * 0.47, Vector2(u, u) * 0.94), Palette.BOARD)
		_socket(c, u)
