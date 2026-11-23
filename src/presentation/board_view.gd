class_name BoardView
extends Node2D
## Renders a PuzzleGame and turns pointer input into transfer requests.
## Holds only *display* state (interpolated positions, fades); the authoritative
## state lives in PuzzleGame and is never modified here except via try_transfer().

signal transferred(result: Dictionary)
signal rejected(reason: String)
signal animation_finished

const Mat = LevelDefinition.Mat
const Static = LevelDefinition.Static

const FLY_TIME := 0.24
const STEP_TIME := 0.11
const DRAG_THRESHOLD := 12.0

var game: PuzzleGame
var lv: LevelDefinition
var cs := 80.0
var origin := Vector2.ZERO
var time := 0.0
var interactive := true
## When false (default since 0.3.2) a held gap does NOT reveal where it may go; the player must
## read the forces. Only the first-encounter tutorial levels turn it on.
var show_destinations := false
## Demo boards (How to play) are silent and do not touch the global FPS cap.
var silent := false
## Force hot-spots (glow where a beam / cart presses). The assist setting turns them off
## after the first levels; a rejected move always reveals them briefly.
var show_hotspots := true
var reveal_t := 0.0
var reveal_family := -1
var reject_t := 0.0
var reject_orphans := PackedInt32Array()

# Display state
var shown_mat := PackedByteArray()
var shown_shuttles: Array[Vector2] = []
var shown_beams: Array = []
var shown_beam_hues: Array = []
var shown_lit_hue: Dictionary = {}
var shown_lit: Dictionary = {}
var shown_frontier_light: Dictionary = {}
var shown_frontier_motion: Dictionary = {}
var shown_active: Array = []
var beam_reveal := 1.0
var old_beams: Array = []
var old_beam_hues: Array = []
var old_beam_alpha := 0.0
var bloom: Dictionary = {}
var dock_glow: Dictionary = {}

# Animation
var phase := ""
var anim_t := 0.0
var fly_src := -1
var fly_dst := -1
var fly_mat := 0
var frames: Array = []
var frame_i := 0
var frame_from: Array[Vector2] = []

# Interaction
var selected := -1
var dests := PackedInt32Array()
var dragging := false
var drag_moved := false
var drag_pos := Vector2.ZERO
var press_pos := Vector2.ZERO
var shake_cell := -1
var shake_t := 0.0
var reject_cell := -1
var reject_reason := ""
var hint_move := Vector2i(-1, -1)
var win_t := -1.0

var _sb := StyleBoxFlat.new()


func setup(g: PuzzleGame) -> void:
	game = g
	lv = g.level
	selected = -1
	dests = PackedInt32Array()
	dragging = false
	hint_move = Vector2i(-1, -1)
	win_t = -1.0
	bloom.clear()
	dock_glow.clear()
	sync_from_game()
	for r in lv.receivers:
		bloom[r] = 1.0 if FunctionalSimulation.receiver_satisfied(lv, shown_lit_hue, r) else 0.0


func sync_from_game() -> void:
	phase = ""
	shown_mat = game.state.mat.duplicate()
	shown_shuttles.clear()
	for c in game.state.shuttle_cells:
		shown_shuttles.append(Vector2(lv.pos(c)))
	_retrace()
	beam_reveal = 1.0
	old_beams = []
	selected = -1
	dests = PackedInt32Array()


func fit(rect: Rect2) -> void:
	if lv == null:
		return
	cs = clampf(minf(rect.size.x / lv.width, rect.size.y / lv.height), 24.0, 132.0)
	origin = rect.position + (rect.size - Vector2(lv.width, lv.height) * cs) * 0.5
	origin = origin.round()


func is_busy() -> bool:
	return phase != ""


func cell_center(i: int) -> Vector2:
	return origin + (Vector2(lv.pos(i)) + Vector2(0.5, 0.5)) * cs


func grid_to_screen(p: Vector2) -> Vector2:
	return origin + (p + Vector2(0.5, 0.5)) * cs


func cell_at(screen: Vector2) -> int:
	var g := (screen - origin) / cs
	var p := Vector2i(floori(g.x), floori(g.y))
	if not lv.in_bounds(p):
		return -1
	return lv.idx_v(p)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if game == null or not interactive:
		return
	var pe := InputAdapter.convert(event)
	if pe.is_empty():
		return
	match pe.kind:
		"press":
			_on_press(pe.pos)
		"move":
			_on_move(pe.pos)
		"release":
			_on_release(pe.pos)


func _on_press(pos: Vector2) -> void:
	Engine.max_fps = 60
	if phase != "":
		finish_animation()
	var c := cell_at(pos)
	if c < 0:
		_deselect()
		return
	if selected >= 0 and dests.has(c):
		_transfer(selected, c)
		return
	if _is_gap(c) and game.state.shuttle_at(c) < 0:
		_select(c)
		dragging = true
		drag_moved = false
		drag_pos = pos
		press_pos = pos
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	if selected >= 0:
		_reject_at(c)
	_deselect()


func _on_move(pos: Vector2) -> void:
	if not dragging:
		return
	drag_pos = pos
	if pos.distance_to(press_pos) > DRAG_THRESHOLD:
		drag_moved = true


func _on_release(pos: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	var c := cell_at(pos)
	if not drag_moved or c == selected:
		return  # tap: keep the selection for tap-to-place
	if c >= 0 and dests.has(c):
		_transfer(selected, c)
	else:
		if c >= 0:
			_reject_at(c)
		_deselect()


func _is_gap(c: int) -> bool:
	return VoidProperty.family_of(game.state.mat[c]) >= 0


func _select(c: int) -> void:
	selected = c
	dests = game.destinations(c)
	_sfx("pick", 1.0 if VoidProperty.family_of(game.state.mat[c]) == VoidProperty.Family.LIGHT else 0.8)


func _deselect() -> void:
	selected = -1
	dests = PackedInt32Array()
	dragging = false


func _reject_at(c: int) -> void:
	var reason := TransferValidator.validate(lv, game.state, game.sim, selected, c)
	if reason == TransferValidator.OK:
		return
	shake_cell = c
	shake_t = 0.4
	reject_cell = c
	reject_reason = reason
	reject_t = 1.6
	reject_orphans = PackedInt32Array()
	# Explain on the board, not only in text.
	if reason == TransferValidator.ERR_NOT_REACHED or reason == TransferValidator.ERR_NOT_SOLID:
		reveal_t = 1.8
		reveal_family = VoidProperty.family_of(game.state.mat[selected])
	elif reason == TransferValidator.ERR_SPLIT:
		var after := game.state.mat.duplicate()
		after[c] = game.state.mat[selected]
		after[selected] = Mat.SOLID
		for o in [lv.object_of[c], lv.object_of[selected]]:
			if o < 0:
				continue
			var comps := GeometryObject.solid_components(lv, after, o)
			for k in range(1, comps.size()):
				reject_orphans.append_array(comps[k])
	_sfx("invalid")
	rejected.emit(reason)


## Public entry used by input, tests and the hint system.
func request_transfer(src: int, dst: int) -> bool:
	if phase != "":
		finish_animation()
	if TransferValidator.validate(lv, game.state, game.sim, src, dst) != TransferValidator.OK:
		selected = src
		_reject_at(dst)
		_deselect()
		return false
	_transfer(src, dst)
	return true


func _transfer(src: int, dst: int) -> void:
	var lit_before := shown_lit.size()
	var res := game.try_transfer(src, dst)
	_deselect()
	if not res.ok:
		_sfx("invalid")
		rejected.emit(res.reason)
		return
	hint_move = Vector2i(-1, -1)
	fly_src = src
	fly_dst = dst
	fly_mat = shown_mat[src]
	frames = res.frames
	frame_i = 0
	phase = "fly"
	anim_t = 0.0
	old_beams = shown_beams
	old_beam_hues = shown_beam_hues
	old_beam_alpha = 1.0
	_sfx("drop", 1.0 if VoidProperty.family_of(fly_mat) == VoidProperty.Family.LIGHT else 0.85)
	set_meta("lit_before", lit_before)
	transferred.emit(res)


func finish_animation() -> void:
	if phase == "":
		return
	sync_from_game()
	animation_finished.emit()


# ---------------------------------------------------------------- simulation mirror

func _retrace() -> void:
	var tmp := BoardState.new()
	tmp.mat = shown_mat
	for k in shown_shuttles.size():
		var p := Vector2i(roundi(shown_shuttles[k].x), roundi(shown_shuttles[k].y))
		tmp.shuttle_cells.append(lv.idx_v(p))
		tmp.shuttle_docked.append(1 if lv.static_cells[lv.idx_v(p)] == Static.DOCK else 0)
	var sim := FunctionalSimulation.evaluate(lv, tmp)
	shown_beams = sim.beams
	shown_beam_hues = sim.beam_hues
	shown_lit_hue = sim.lit_hue
	shown_lit = sim.lit
	shown_frontier_light = sim.frontier_light
	shown_frontier_motion = sim.frontier_motion
	shown_active = sim.shuttle_active
	beam_reveal = 0.0


func _process(delta: float) -> void:
	if game == null:
		return
	time += delta
	if phase == "fly":
		anim_t += delta / FLY_TIME
		if anim_t >= 1.0:
			shown_mat = game.state.mat.duplicate()
			_retrace()
			if shown_lit.size() > int(get_meta("lit_before", 0)):
				_sfx("light")
			if frames.is_empty():
				phase = ""
				animation_finished.emit()
			else:
				phase = "roll"
				anim_t = 0.0
				frame_from = shown_shuttles.duplicate()
	elif phase == "roll":
		anim_t += delta / STEP_TIME
		var target: PackedInt32Array = frames[frame_i]
		var e := minf(anim_t, 1.0)
		for k in shown_shuttles.size():
			shown_shuttles[k] = frame_from[k].lerp(Vector2(lv.pos(target[k])), e)
		if anim_t >= 1.0:
			frame_i += 1
			anim_t = 0.0
			frame_from = shown_shuttles.duplicate()
			_sfx("roll", 0.9 + 0.2 * (frame_i % 3))
			var lit_n := shown_lit.size()
			_retrace()
			beam_reveal = 1.0
			if shown_lit.size() > lit_n:
				_sfx("light")
			if frame_i >= frames.size():
				phase = ""
				sync_from_game()
				for d in lv.docks:
					if game.state.shuttle_at(d) >= 0 and not dock_glow.has(d):
						_sfx("dock")
				animation_finished.emit()
	beam_reveal = minf(1.0, beam_reveal + delta / 0.22)
	old_beam_alpha = maxf(0.0, old_beam_alpha - delta / 0.18)
	for r in lv.receivers:
		var target_b := 1.0 if FunctionalSimulation.receiver_satisfied(lv, shown_lit_hue, r) else 0.0
		bloom[r] = move_toward(float(bloom.get(r, 0.0)), target_b, delta * 2.6)
	for d in lv.docks:
		var occ := false
		for s in shown_shuttles:
			if s.distance_to(Vector2(lv.pos(d))) < 0.1:
				occ = true
		if occ:
			dock_glow[d] = minf(1.0, float(dock_glow.get(d, 0.0)) + delta * 3.0)
		else:
			dock_glow.erase(d)
	shake_t = maxf(0.0, shake_t - delta)
	reveal_t = maxf(0.0, reveal_t - delta)
	reject_t = maxf(0.0, reject_t - delta)
	if win_t >= 0.0:
		win_t += delta
	_update_fps_cap()
	queue_redraw()


## Battery: only ambient pulses run while idle, which look fine at 30 FPS.
## Anything the player is touching or watching resolve runs at 60 FPS.
func _sfx(name: String, pitch: float = 1.0) -> void:
	if not silent:
		Sfx.play(name, pitch)


func _update_fps_cap() -> void:
	if silent:
		return
	if not is_visible_in_tree():
		Engine.max_fps = 60  # menus scroll; they are cheap to draw
		return
	var animating := phase != "" or dragging or selected >= 0 or (win_t >= 0.0 and win_t < 2.0) or shake_t > 0.0 or beam_reveal < 1.0
	for r in bloom:
		var target_b := 1.0 if FunctionalSimulation.receiver_satisfied(lv, shown_lit_hue, r) else 0.0
		if absf(float(bloom[r]) - target_b) > 0.001:
			animating = true
	Engine.max_fps = 60 if animating else 30


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if lv == null:
		return
	var board := Rect2(origin, Vector2(lv.width, lv.height) * cs)
	_rounded(board.grow(cs * 0.22).grow_individual(0, 0, 0, cs * 0.06), Color(0, 0, 0, 0.25), cs * 0.32)
	_rounded(board.grow(cs * 0.18), Palette.BOARD, cs * 0.28, Palette.BOARD_EDGE, 2)
	for y in lv.height + 1:
		for x in lv.width + 1:
			draw_circle(origin + Vector2(x, y) * cs, maxf(1.5, cs * 0.025), Palette.GRID_DOT)

	for i in lv.cell_count():
		var s := lv.static_cells[i]
		if s == Static.DOCK:
			_draw_dock(i)
		elif s == Static.WALL:
			_draw_wall(i)
	_draw_slabs()
	for i in lv.cell_count():
		match lv.static_cells[i]:
			Static.MIRROR_SLASH, Static.MIRROR_BACKSLASH:
				_draw_mirror(i)
			Static.EMITTER:
				_draw_emitter(i)
			Static.RECEIVER:
				_draw_flower(i)
	_draw_beams(old_beams, old_beam_hues, old_beam_alpha, 1.0)
	_draw_beams(shown_beams, shown_beam_hues, 1.0, beam_reveal)
	for k in shown_shuttles.size():
		_draw_cart(k)
	if phase == "" and selected < 0 and (show_hotspots or reveal_t > 0.0):
		_draw_hotspots()
	if reject_t > 0.0:
		_draw_rejection()
	_draw_selection()
	if phase == "fly":
		var e := ease(anim_t, -2.2)
		var a := cell_center(fly_src)
		var b := cell_center(fly_dst)
		var lift := Vector2(0, -cs * 0.6 * sin(e * PI))
		_draw_token(a.lerp(b, e) + lift, fly_mat, 1.15, 1.0)
	if hint_move.x >= 0 and phase == "" and selected < 0:
		_draw_hint()
	if win_t >= 0.0:
		_draw_win()


func _rounded(r: Rect2, c: Color, radius: float, border: Color = Color.TRANSPARENT, bw: int = 0) -> void:
	_sb.bg_color = c
	_sb.set_corner_radius_all(int(radius))
	_sb.border_color = border
	_sb.set_border_width_all(bw)
	_sb.anti_aliasing = true
	_sb.draw(get_canvas_item(), r)


func _cell_rect(i: int) -> Rect2:
	return Rect2(origin + Vector2(lv.pos(i)) * cs, Vector2(cs, cs))


func _same_solid(i: int, d: Vector2i) -> bool:
	var q := lv.pos(i) + d
	if not lv.in_bounds(q):
		return false
	var j := lv.idx_v(q)
	return lv.object_of[j] == lv.object_of[i] and _mat_for_draw(j) == Mat.SOLID


func _mat_for_draw(i: int) -> int:
	if phase == "fly" and i == fly_src:
		return Mat.SOLID if anim_t > 0.55 else shown_mat[i]
	return shown_mat[i]


func _draw_slabs() -> void:
	var ins := cs * 0.06
	var rad := cs * 0.2
	for pass_i in 2:
		for i in lv.cell_count():
			var o := lv.object_of[i]
			if o < 0:
				continue
			var m := _mat_for_draw(i)
			var col := Palette.slab(o)
			var r := _cell_rect(i)
			if shake_t > 0.0 and i == shake_cell:
				r.position.x += sin(time * 60.0) * cs * 0.05 * shake_t / 0.4
			if m != Mat.SOLID:
				if pass_i == 1:
					_draw_socket(i, r, col, m)
				continue
			var l := not _same_solid(i, Dir.LEFT)
			var t := not _same_solid(i, Dir.UP)
			var rt := not _same_solid(i, Dir.RIGHT)
			var b := not _same_solid(i, Dir.DOWN)
			var rr := r.grow_individual(-ins if l else 0.5, -ins if t else 0.5, -ins if rt else 0.5, -ins if b else 0.5)
			_sb.border_width_left = 0
			_sb.set_border_width_all(0)
			_sb.anti_aliasing = true
			_sb.corner_radius_top_left = int(rad) if (l and t) else 0
			_sb.corner_radius_top_right = int(rad) if (rt and t) else 0
			_sb.corner_radius_bottom_left = int(rad) if (l and b) else 0
			_sb.corner_radius_bottom_right = int(rad) if (rt and b) else 0
			if pass_i == 0:
				if not b:
					continue  # only exposed bottom edges cast the slab's drop edge
				# Neighbours that cover our shadow from below would leave a notch; pull the shadow in there.
				var sl := 0.0 if (l or not _same_solid(lv.idx_v(lv.pos(i) + Dir.LEFT), Dir.DOWN)) else ins
				var sr := 0.0 if (rt or not _same_solid(lv.idx_v(lv.pos(i) + Dir.RIGHT), Dir.DOWN)) else ins
				_sb.bg_color = col.darkened(0.42)
				_sb.draw(get_canvas_item(), Rect2(rr.position + Vector2(sl, cs * 0.08), rr.size - Vector2(sl + sr, 0)))
			else:
				_sb.bg_color = col
				_sb.draw(get_canvas_item(), rr)
				if t:
					draw_line(rr.position + Vector2(rad * 0.6 if l else 0.0, 2), rr.position + Vector2(rr.size.x - (rad * 0.6 if rt else 0.0), 2), col.lightened(0.35), maxf(1.5, cs * 0.03))
				if o >= 0 and phase == "fly" and i == fly_src:
					var k := clampf((anim_t - 0.45) / 0.55, 0.0, 1.0)
					_rounded(rr.grow(-cs * 0.2 * (1.0 - k)), Color(1, 1, 1, 0.35 * (1.0 - k)), cs * 0.15)


func _draw_socket(i: int, r: Rect2, col: Color, m: int) -> void:
	var sr := r.grow(-cs * 0.1)
	_rounded(Rect2(sr.position + Vector2(0, cs * 0.04), sr.size), Color(0, 0, 0, 0.3), cs * 0.18)
	_rounded(sr, Palette.SOCKET, cs * 0.18, Color(col, 0.75), maxi(2, int(cs * 0.045)))
	var hide := (phase == "fly" and i == fly_dst) or (dragging and drag_moved and i == selected)
	if hide:
		return
	var c := r.get_center()
	var sc := 1.0
	if i == selected:
		sc = 1.18 + 0.04 * sin(time * 8.0)
		c += Vector2(0, -cs * 0.08)
	else:
		sc = 1.0 + 0.03 * sin(time * 2.4 + i)
	if i == shake_cell and shake_t > 0.0:
		c.x += sin(time * 60.0) * cs * 0.05 * shake_t / 0.4
	_draw_token(c, m, sc, 1.0)


## A gap token: functional emptiness. Light = glowing ring, Motion = grooved square.
func _token_color(m: int) -> Color:
	if m == Mat.LIGHT_RED:
		return Palette.RED_GLASS
	if m == Mat.LIGHT_BLUE:
		return Palette.BLUE_GLASS
	if m == Mat.MOTION_GAP:
		return Palette.MOTION
	return Palette.LIGHT


func _draw_token(c: Vector2, m: int, sc: float, alpha: float) -> void:
	var r := cs * 0.3 * sc
	if VoidProperty.family_of(m) == VoidProperty.Family.LIGHT:
		var col := _token_color(m)
		var core := Palette.LIGHT_CORE if m == Mat.LIGHT_GAP else (Palette.RED_CORE if m == Mat.LIGHT_RED else Palette.BLUE_CORE)
		draw_circle(c, r * 1.45, Color(col, 0.22 * alpha))
		draw_circle(c, r, Color(col, (0.22 if m == Mat.LIGHT_GAP else 0.45) * alpha))
		draw_arc(c, r, 0, TAU, 40, Color(col, alpha), maxf(2.0, cs * 0.06), true)
		draw_arc(c, r * 0.62, -PI * 0.85, -PI * 0.35, 12, Color(core, 0.9 * alpha), maxf(1.5, cs * 0.035), true)
		# Shape marker so colour is never the only cue: dot (clear), triangle (red), square (blue).
		if m == Mat.LIGHT_RED:
			var t := r * 0.32
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -t), c + Vector2(t * 0.9, t * 0.7), c + Vector2(-t * 0.9, t * 0.7)]), Color(core, alpha))
		elif m == Mat.LIGHT_BLUE:
			var q := r * 0.24
			draw_rect(Rect2(c - Vector2(q, q), Vector2(q, q) * 2.0), Color(core, alpha))
		else:
			draw_circle(c, r * 0.16, Color(core, alpha))
	elif m == Mat.MOTION_GAP:
		var h := r * 0.95
		var rr := Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0)
		_rounded(rr.grow(r * 0.25), Color(Palette.MOTION, 0.14 * alpha), r * 0.5)
		_rounded(rr, Color(Palette.MOTION, 0.18 * alpha), r * 0.35, Color(Palette.MOTION, alpha), maxi(2, int(cs * 0.055)))
		var w := maxf(2.0, cs * 0.05)
		draw_line(c + Vector2(-h * 0.6, -h * 0.32), c + Vector2(h * 0.6, -h * 0.32), Color(Palette.MOTION, alpha), w, true)
		draw_line(c + Vector2(-h * 0.6, h * 0.32), c + Vector2(h * 0.6, h * 0.32), Color(Palette.MOTION, alpha), w, true)


func _draw_wall(i: int) -> void:
	var r := _cell_rect(i).grow(-cs * 0.04)
	_rounded(Rect2(r.position + Vector2(0, cs * 0.07), r.size), Palette.WALL.darkened(0.45), cs * 0.12)
	_rounded(r, Palette.WALL, cs * 0.12)
	draw_line(r.position + Vector2(cs * 0.15, cs * 0.35), r.position + Vector2(cs * 0.55, cs * 0.35), Palette.WALL_TOP, 2.0)
	draw_line(r.position + Vector2(cs * 0.35, cs * 0.65), r.position + Vector2(cs * 0.8, cs * 0.65), Palette.WALL_TOP, 2.0)


func _draw_dock(i: int) -> void:
	var r := _cell_rect(i).grow(-cs * 0.12)
	var g := float(dock_glow.get(i, 0.0))
	_rounded(r, Color(Palette.DOCK, 0.08 + 0.25 * g), cs * 0.16, Color(Palette.DOCK, 0.55 + 0.45 * g), maxi(2, int(cs * 0.04)))
	var c := r.get_center()
	if g > 0.0:
		draw_circle(c, cs * 0.55 * g, Color(Palette.DOCK, 0.12 * g))
	else:
		var p := c + Vector2(-cs * 0.12, cs * 0.2)
		draw_line(p, p + Vector2(0, -cs * 0.4), Color(Palette.DOCK, 0.8), 2.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -cs * 0.4), p + Vector2(cs * 0.28, -cs * 0.31), p + Vector2(0, -cs * 0.22)]), Color(Palette.DOCK, 0.8))


func _draw_mirror(i: int) -> void:
	var r := _cell_rect(i).grow(-cs * 0.16)
	var a := r.position + Vector2(0, r.size.y)
	var b := r.position + Vector2(r.size.x, 0)
	if lv.static_cells[i] == Static.MIRROR_BACKSLASH:
		a = r.position
		b = r.end
	draw_circle(_cell_rect(i).get_center(), cs * 0.12, Palette.BOARD_EDGE)
	draw_line(a + Vector2(0, cs * 0.05), b + Vector2(0, cs * 0.05), Color(0, 0, 0, 0.3), cs * 0.12, true)
	draw_line(a, b, Palette.MIRROR, cs * 0.1, true)
	draw_line(a.lerp(b, 0.15), a.lerp(b, 0.55), Color(1, 1, 1, 0.9), cs * 0.03, true)


func _draw_emitter(i: int) -> void:
	var c := cell_center(i)
	var d := Vector2(lv.emitter_dir[i])
	draw_circle(c, cs * 0.44 + sin(time * 3.0) * cs * 0.02, Color(Palette.LIGHT, 0.12))
	draw_circle(c + Vector2(0, cs * 0.06), cs * 0.3, Color(0, 0, 0, 0.3))
	draw_circle(c, cs * 0.3, Color("6b5a8e"))
	draw_circle(c, cs * 0.2, Palette.LIGHT)
	draw_circle(c, cs * 0.1, Palette.LIGHT_CORE)
	var n := Vector2(-d.y, d.x)
	var tip := c + d * cs * 0.46
	draw_colored_polygon(PackedVector2Array([tip, c + d * cs * 0.28 + n * cs * 0.13, c + d * cs * 0.28 - n * cs * 0.13]), Palette.LIGHT)


func _draw_flower(i: int) -> void:
	var c := cell_center(i)
	var b := float(bloom.get(i, 0.0))
	var be := ease(b, -2.0)
	draw_line(c + Vector2(0, cs * 0.1), c + Vector2(0, cs * 0.42), Color("6fbf8a"), maxf(2.0, cs * 0.05), true)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, cs * 0.3), c + Vector2(cs * 0.18, cs * 0.2), c + Vector2(cs * 0.04, cs * 0.36)]), Color("6fbf8a"))
	var need: int = lv.receiver_hue.get(i, 0)
	var on_col := Palette.FLOWER_ON if need == 0 else (Palette.RED_GLASS if need == 1 else Palette.BLUE_GLASS)
	if be > 0.01:
		draw_circle(c, cs * (0.5 + 0.05 * sin(time * 3.0)) * be, Color(on_col, 0.16 * be))
	var col := Palette.FLOWER_OFF.lerp(on_col, maxf(be, 0.45 if need != 0 else 0.0))
	var petals := 6
	for k in petals:
		var ang := TAU * k / petals + time * 0.3 * be
		var off := Vector2(cos(ang), sin(ang)) * cs * (0.06 + 0.15 * be)
		draw_circle(c + off, cs * (0.1 + 0.06 * be), col)
	draw_circle(c, cs * (0.08 + 0.04 * be), Palette.FLOWER_OFF.darkened(0.2).lerp(Palette.FLOWER_CENTER, be))
	if need != 0:
		# Coloured flowers wear their colour (and shape) even before blooming.
		var mk := Palette.RED_GLASS if need == 1 else Palette.BLUE_GLASS
		var rr := cs * 0.065
		if need == 1:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rr * 1.2), c + Vector2(rr, rr * 0.8), c + Vector2(-rr, rr * 0.8)]), mk)
		else:
			draw_rect(Rect2(c - Vector2(rr, rr) * 0.85, Vector2(rr, rr) * 1.7), mk)


func _draw_beams(beams: Array, hues: Array, alpha: float, reveal: float) -> void:
	if alpha <= 0.01:
		return
	var flick := 0.9 + 0.1 * sin(time * 9.0)
	for bi in beams.size():
		var p: PackedVector2Array = beams[bi]
		var hc: Array[Color] = Palette.hue_colors(int(hues[bi]) if bi < hues.size() else 0)
		if p.size() < 2:
			continue
		var scr := PackedVector2Array()
		for q in p:
			scr.append(grid_to_screen(q))
		scr = _cut_polyline(scr, reveal)
		if scr.size() < 2:
			continue
		draw_polyline(scr, Color(hc[0], 0.13 * alpha * flick), cs * 0.42, true)
		draw_polyline(scr, Color(hc[0], 0.4 * alpha), cs * 0.16, true)
		draw_polyline(scr, Color(hc[1], 0.95 * alpha), maxf(2.0, cs * 0.05), true)
		draw_circle(scr[scr.size() - 1], cs * 0.09, Color(hc[1], 0.8 * alpha))


func _cut_polyline(p: PackedVector2Array, f: float) -> PackedVector2Array:
	if f >= 1.0:
		return p
	var total := 0.0
	for k in range(1, p.size()):
		total += p[k - 1].distance_to(p[k])
	var want := total * f
	var out := PackedVector2Array([p[0]])
	for k in range(1, p.size()):
		var seg := p[k - 1].distance_to(p[k])
		if want <= seg:
			out.append(p[k - 1].lerp(p[k], want / maxf(seg, 0.001)))
			return out
		want -= seg
		out.append(p[k])
	return out


func _draw_cart(k: int) -> void:
	var sh: Dictionary = lv.shuttles[k]
	var d: Vector2i = sh.dir
	var c := grid_to_screen(shown_shuttles[k])
	var lit := false
	var ci := lv.idx_v(Vector2i(roundi(shown_shuttles[k].x), roundi(shown_shuttles[k].y)))
	lit = shown_lit.has(ci)
	var ang := Vector2(d).angle()
	var bob := sin(time * 4.0 + k) * cs * 0.01
	draw_set_transform(c + Vector2(0, bob), ang)
	var L := cs * 0.36
	var W := cs * 0.25
	draw_rect(Rect2(Vector2(-L, -W) + Vector2(0, cs * 0.05), Vector2(L, W) * 2.0), Color(0, 0, 0, 0.25))
	var body := Palette.CART
	if sh.solar:
		body = Palette.SOLAR.lerp(Color.WHITE, 0.15) if lit else Palette.SOLAR.darkened(0.35)
	draw_rect(Rect2(Vector2(-L, -W), Vector2(L, W) * 2.0), body)
	draw_rect(Rect2(Vector2(-L, -W), Vector2(L * 2.0, W * 0.35)), body.lightened(0.25))
	for sx in [-0.55, 0.55]:
		for sy in [-1.0, 1.0]:
			draw_circle(Vector2(L * sx, W * sy), cs * 0.07, Color("2b2d42"))
	draw_colored_polygon(PackedVector2Array([Vector2(L + cs * 0.12, 0), Vector2(L - cs * 0.02, -W * 0.6), Vector2(L - cs * 0.02, W * 0.6)]), body.darkened(0.3))
	if sh.solar:
		var pr := Rect2(Vector2(-L * 0.6, -W * 0.6), Vector2(L * 1.1, W * 1.2))
		draw_rect(pr, Color("27407a"))
		draw_line(pr.position + Vector2(pr.size.x * 0.5, 0), pr.position + Vector2(pr.size.x * 0.5, pr.size.y), Color("8fb6ff"), 1.5)
		draw_line(pr.position + Vector2(0, pr.size.y * 0.5), pr.position + Vector2(pr.size.x, pr.size.y * 0.5), Color("8fb6ff"), 1.5)
		if lit:
			draw_circle(Vector2.ZERO, cs * 0.45, Color(Palette.LIGHT, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_hotspots() -> void:
	var pulse := 0.5 + 0.5 * sin(time * 4.0)
	var revealing := reveal_t > 0.0 and not show_hotspots
	if revealing:
		pulse = 0.5 + 0.5 * sin(time * 10.0)
	var boost := 1.6 if reveal_t > 0.0 else 1.0
	var show_light := not revealing or reveal_family == VoidProperty.Family.LIGHT
	var show_motion := not revealing or reveal_family == VoidProperty.Family.MOTION
	for pts in (shown_beams if show_light else []):
		var p: PackedVector2Array = pts
		if p.size() < 2:
			continue
		var end := p[p.size() - 1]
		var dir := (end - p[p.size() - 2]).normalized()
		var cell := Vector2i(roundi(end.x + dir.x * 0.5), roundi(end.y + dir.y * 0.5))
		if not lv.in_bounds(cell) or not shown_frontier_light.has(lv.idx_v(cell)):
			continue
		var s := grid_to_screen(end)
		draw_circle(s, cs * (0.16 + 0.08 * pulse) * boost, Color(Palette.LIGHT, 0.35 + 0.3 * pulse))
		for k in 3:
			var a := time * 2.0 + k * TAU / 3.0
			draw_circle(s + Vector2(cos(a), sin(a)) * cs * 0.22, cs * 0.03, Color(Palette.LIGHT_CORE, 0.7))
	for k in (range(shown_shuttles.size()) if show_motion else []):
		if k >= shown_active.size() or not shown_active[k]:
			continue
		var d: Vector2i = lv.shuttles[k].dir
		var nxt := Vector2i(roundi(shown_shuttles[k].x), roundi(shown_shuttles[k].y)) + d
		if not lv.in_bounds(nxt) or not shown_frontier_motion.has(lv.idx_v(nxt)):
			continue
		var face := grid_to_screen(Vector2(nxt) - Vector2(d) * 0.5)
		var n := Vector2(-d.y, d.x)
		for j in 2:
			var off := Vector2(d) * cs * (0.08 * j - 0.04 + 0.05 * pulse)
			var tip := face + off
			draw_polyline(PackedVector2Array([tip - Vector2(d) * cs * 0.1 + n * cs * 0.13, tip, tip - Vector2(d) * cs * 0.1 - n * cs * 0.13]), Color(Palette.MOTION, 0.5 + 0.4 * pulse), maxf(2.0, cs * 0.05), true)


func _draw_selection() -> void:
	if selected < 0:
		return
	var m := game.state.mat[selected]
	var col := _token_color(m)
	var pulse := 0.5 + 0.5 * sin(time * 6.0)
	if show_destinations:
		for d in dests:
			var r := _cell_rect(d).grow(-cs * 0.06)
			_rounded(r, Color(col, 0.12 + 0.1 * pulse), cs * 0.2, Color(col, 0.6 + 0.4 * pulse), maxi(2, int(cs * 0.05)))
			_draw_token(r.get_center(), m, 0.8, 0.35 + 0.25 * pulse)
		if dests.is_empty():
			draw_arc(cell_center(selected), cs * 0.46, 0, TAU, 32, Color(Palette.DANGER, 0.5), 2.0, true)
	if dragging and drag_moved:
		var hc := cell_at(drag_pos)
		if show_destinations and hc >= 0 and dests.has(hc):
			_rounded(_cell_rect(hc).grow(-cs * 0.02), Color(col, 0.25), cs * 0.22)
		draw_circle(drag_pos + Vector2(0, cs * 0.12), cs * 0.25, Color(0, 0, 0, 0.25))
		_draw_token(drag_pos, m, 1.25, 1.0)


func _draw_hint() -> void:
	var a := cell_center(hint_move.x)
	var b := cell_center(hint_move.y)
	var t := fmod(time, 1.8) / 1.8
	var e := ease(clampf((t - 0.15) / 0.6, 0.0, 1.0), -2.0)
	var steps := 10
	for k in steps:
		var q := a.lerp(b, float(k) / steps)
		draw_circle(q, cs * 0.035, Color(1, 1, 1, 0.25))
	var p := a.lerp(b, e)
	var press := 1.0 if (t > 0.1 and t < 0.8) else 0.0
	draw_circle(p + Vector2(cs * 0.08, cs * 0.12), cs * 0.17, Color(0, 0, 0, 0.25))
	draw_circle(p, cs * 0.17, Color(1, 1, 1, 0.85))
	draw_arc(p, cs * (0.24 + 0.1 * (1.0 - press)), 0, TAU, 28, Color(1, 1, 1, 0.5 * press + 0.2), 2.0, true)


func _draw_win() -> void:
	var t := win_t
	var targets: Array = []
	for r in lv.receivers:
		targets.append(cell_center(r))
	for d in lv.docks:
		targets.append(cell_center(d))
	for c: Vector2 in targets:
		var rad := cs * (0.3 + t * 2.2)
		var a := clampf(1.0 - t / 1.2, 0.0, 1.0)
		draw_arc(c, rad, 0, TAU, 48, Color(Palette.LIGHT_CORE, 0.6 * a), maxf(2.0, cs * 0.06 * a), true)
		for k in 10:
			var ang := TAU * k / 10.0 + 0.3
			var dist := cs * (0.4 + t * 1.6)
			var pc: Vector2 = c + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, t * t * cs * 0.8)
			draw_circle(pc, cs * 0.05 * a, Palette.slab(k).lightened(0.3) if k % 2 == 0 else Color(Palette.LIGHT, a))



## Visual reason for a rejected drop: a red cross on the target and, for a split,
## the chunk that would break off shown in red with a crack.
func _draw_rejection() -> void:
	var a := clampf(reject_t / 0.6, 0.0, 1.0)
	if reject_cell >= 0:
		var c := cell_center(reject_cell)
		var r := cs * 0.22
		var col := Color(Palette.DANGER, 0.85 * a)
		draw_line(c + Vector2(-r, -r), c + Vector2(r, r), col, maxf(3.0, cs * 0.07), true)
		draw_line(c + Vector2(r, -r), c + Vector2(-r, r), col, maxf(3.0, cs * 0.07), true)
	for o in reject_orphans:
		var rr := _cell_rect(o).grow(-cs * 0.08)
		_rounded(rr, Color(Palette.DANGER, 0.32 * a), cs * 0.16, Color(Palette.DANGER, 0.9 * a), maxi(2, int(cs * 0.05)))
		var p0 := rr.position + Vector2(rr.size.x * 0.2, 0)
		draw_polyline(PackedVector2Array([p0, p0 + Vector2(rr.size.x * 0.25, rr.size.y * 0.35), p0 + Vector2(rr.size.x * 0.1, rr.size.y * 0.6), p0 + Vector2(rr.size.x * 0.4, rr.size.y)]), Color(Palette.BG_TOP, 0.9 * a), maxf(2.0, cs * 0.04), true)
