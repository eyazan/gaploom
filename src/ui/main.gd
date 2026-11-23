extends Control
## Application shell: title, level select, gameplay HUD, completion overlay.
## All UI is built in code so the project has no binary scene dependencies.

const REASON_KEYS := {
	"not_reached": "MSG_NOT_REACHED",
	"would_split": "MSG_SPLIT",
	"occupied": "MSG_OCCUPIED",
	"not_solid": "MSG_NOT_SOLID",
}

var save: SaveGame
var sfx: Sfx
var music: Music
var theme_res: Theme
var title_font: FontVariation

var current := 0
var game: PuzzleGame
var board: BoardView

var screen_title: Control
var screen_select: Control
var screen_game: Control
var overlay: PanelContainer

var lbl_level: Label
var lbl_moves: Label
var lbl_tip: Label
var gap_counter: GapCounter
var btn_undo: IconButton
var btn_restart: IconButton
var btn_hint: IconButton
var btn_help: IconButton
var howto: HowTo
var tip_tween: Tween
var win_pending := false
var hints_used := 0
var daily_day := 0          # > 0 while playing the daily puzzle
var btn_daily: Button
var lbl_daily: Label
var hint_key := ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	save = SaveGame.load_from()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.enabled = bool(save.settings.get("sfx", true))
	music = Music.new()
	add_child(music)
	music.enabled = bool(save.settings.get("music", true))
	_build_theme()
	_build_background()
	_build_title()
	_build_select()
	_build_game()
	_build_overlay()
	howto = HowTo.new()
	howto.visible = false
	howto.closed.connect(_on_howto_closed)
	add_child(howto)
	resized.connect(_layout)
	if save.first_launch:
		start_level(1)
	else:
		show_screen(screen_title)
		music.play("lighthouse")
	_layout()


# ---------------------------------------------------------------- building

func _build_theme() -> void:
	theme_res = Theme.new()
	theme_res.default_font_size = 30
	var base_font := ThemeDB.fallback_font
	title_font = FontVariation.new()
	title_font.base_font = base_font
	title_font.spacing_glyph = 10
	title_font.variation_embolden = 0.9
	theme_res.set_color("font_color", "Label", Palette.TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.BUTTON_HI if state == "hover" else (Palette.ACCENT if state == "pressed" else Palette.BUTTON)
		if state == "focus":
			sb.draw_center = false
		sb.set_corner_radius_all(28)
		sb.content_margin_left = 36
		sb.content_margin_right = 36
		sb.content_margin_top = 18
		sb.content_margin_bottom = 18
		theme_res.set_stylebox(state, "Button", sb)
	theme_res.set_color("font_color", "Button", Palette.TEXT)
	theme_res.set_color("font_hover_color", "Button", Palette.TEXT)
	theme_res.set_color("font_pressed_color", "Button", Palette.BG_TOP)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Palette.PANEL
	panel.set_corner_radius_all(36)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 28
	panel.content_margin_bottom = 36
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 24
	theme_res.set_stylebox("panel", "PanelContainer", panel)
	theme = theme_res


func _build_background() -> void:
	var g := Gradient.new()
	g.set_color(0, Palette.BG_TOP)
	g.set_color(1, Palette.BG_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var bg := TextureRect.new()
	bg.texture = tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _label(text: String, size: int, color: Color = Palette.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_title() -> void:
	screen_title = Control.new()
	screen_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_title)
	var art := TitleArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_title.add_child(art)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_title.add_child(box)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 380)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var logo := _label("GAPLOOM", 92, Palette.TEXT)
	logo.add_theme_font_override("font", title_font)
	box.add_child(logo)
	box.add_child(_label(tr("APP_TAGLINE"), 30, Palette.TEXT_DIM))
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	box.add_child(spacer2)
	var play := Button.new()
	play.text = tr("BTN_PLAY")
	play.add_theme_font_size_override("font_size", 40)
	play.custom_minimum_size = Vector2(340, 0)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func(): Sfx.play("tap"); start_level(_next_unsolved()))
	box.add_child(play)
	btn_daily = Button.new()
	btn_daily.custom_minimum_size = Vector2(340, 0)
	btn_daily.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_daily.add_theme_color_override("font_color", Palette.ACCENT)
	btn_daily.pressed.connect(func(): Sfx.play("tap"); start_daily())
	box.add_child(btn_daily)
	lbl_daily = _label("", 24, Palette.TEXT_DIM)
	box.add_child(lbl_daily)
	var levels := Button.new()
	levels.text = tr("BTN_LEVELS")
	levels.custom_minimum_size = Vector2(340, 0)
	levels.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	levels.pressed.connect(func(): Sfx.play("tap"); open_select())
	box.add_child(levels)
	var howto_btn := Button.new()
	howto_btn.text = tr("BTN_HOWTO")
	howto_btn.custom_minimum_size = Vector2(340, 0)
	howto_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	howto_btn.pressed.connect(func(): Sfx.play("tap"); open_howto())
	box.add_child(howto_btn)
	var assist_btn := Button.new()
	assist_btn.custom_minimum_size = Vector2(340, 0)
	assist_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	assist_btn.add_theme_font_size_override("font_size", 26)
	assist_btn.text = _assist_label()
	assist_btn.pressed.connect(func():
		var modes: Array = SaveGame.ASSIST_MODES
		var i := modes.find(str(save.settings.get("assist", "auto")))
		save.settings["assist"] = modes[(i + 1) % modes.size()]
		save.save()
		assist_btn.text = _assist_label()
		Sfx.play("tap"))
	box.add_child(assist_btn)
	var snd := IconButton.new("sound_on" if sfx.enabled else "sound_off", 84)
	snd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	snd.pressed.connect(func():
		sfx.enabled = not sfx.enabled
		save.settings["sfx"] = sfx.enabled
		save.save()
		snd.icon_kind = "sound_on" if sfx.enabled else "sound_off"
		snd.queue_redraw()
		Sfx.play("tap"))
	var mus := IconButton.new("music_on" if music.enabled else "music_off", 84)
	mus.pressed.connect(func():
		music.set_enabled(not music.enabled)
		save.settings["music"] = music.enabled
		save.save()
		mus.icon_kind = "music_on" if music.enabled else "music_off"
		mus.queue_redraw()
		Sfx.play("tap"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(row)
	row.add_child(snd)
	row.add_child(mus)


func _build_select() -> void:
	screen_select = Control.new()
	screen_select.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_select)


func _rebuild_select() -> void:
	for c in screen_select.get_children():
		c.queue_free()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_select.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 48)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)
	var head := HBoxContainer.new()
	var back := IconButton.new("back", 84)
	back.pressed.connect(func(): Sfx.play("tap"); show_screen(screen_title))
	head.add_child(back)
	var t := _label("GAPLOOM", 44)
	t.add_theme_font_override("font", title_font)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(84, 0)
	head.add_child(pad)
	col.add_child(head)
	for w in LevelCatalog.WORLDS:
		var done := 0
		var flags: Array[bool] = []
		for n in range(w.first, w.last + 1):
			var d := save.is_done("level_%02d" % n)
			flags.append(d)
			if d:
				done += 1
		var wl := _label("%s   %d/%d" % [tr("WORLD_" + str(w.id).to_upper()), done, w.last - w.first + 1], 34)
		col.add_child(wl)
		var dio := Diorama.new()
		dio.world_id = w.id
		dio.restored = flags
		col.add_child(dio)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(grid)
		for n in range(w.first, w.last + 1):
			var lb := LevelButton.new()
			lb.number = n
			lb.stars = save.stars("level_%02d" % n)
			lb.perfect = save.is_perfect("level_%02d" % n)
			lb.locked = not _unlocked(n)
			lb.disabled = lb.locked
			var nn := n
			lb.pressed.connect(func(): Sfx.play("tap"); start_level(nn))
			grid.add_child(lb)


func _build_game() -> void:
	screen_game = Control.new()
	screen_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_game)
	board = BoardView.new()
	screen_game.add_child(board)
	board.transferred.connect(_on_transferred)
	board.animation_finished.connect(_on_board_settled)
	board.rejected.connect(_on_rejected)

	var back := IconButton.new("back", 84)
	back.name = "Back"
	back.pressed.connect(func(): Sfx.play("tap"); open_select())
	screen_game.add_child(back)
	lbl_level = _label("", 30)
	screen_game.add_child(lbl_level)
	gap_counter = GapCounter.new()
	screen_game.add_child(gap_counter)
	lbl_tip = _label("", 30, Palette.TEXT_DIM)
	lbl_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_tip.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	screen_game.add_child(lbl_tip)
	lbl_moves = _label("", 28, Palette.TEXT_DIM)
	screen_game.add_child(lbl_moves)
	btn_undo = IconButton.new("undo", 104)
	btn_undo.pressed.connect(_on_undo)
	screen_game.add_child(btn_undo)
	btn_restart = IconButton.new("restart", 104)
	btn_restart.pressed.connect(_on_restart)
	screen_game.add_child(btn_restart)
	btn_hint = IconButton.new("hint", 104)
	btn_hint.pressed.connect(_on_hint)
	screen_game.add_child(btn_hint)
	btn_help = IconButton.new("help", 104)
	btn_help.pressed.connect(func(): Sfx.play("tap"); open_howto())
	screen_game.add_child(btn_help)


func _build_overlay() -> void:
	overlay = PanelContainer.new()
	overlay.visible = false
	add_child(overlay)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 14)
	overlay.add_child(v)
	var title := _label(tr("LBL_RESTORED"), 48)
	title.name = "Title"
	v.add_child(title)
	var stars := StarRow.new()
	stars.name = "Stars"
	v.add_child(stars)
	var dio := Diorama.new()
	dio.name = "Dio"
	dio.custom_minimum_size = Vector2(0, 230)
	v.add_child(dio)
	var info := _label("", 26, Palette.TEXT_DIM)
	info.name = "Info"
	v.add_child(info)
	var share := Button.new()
	share.name = "Share"
	share.text = tr("BTN_SHARE")
	share.custom_minimum_size = Vector2(300, 0)
	share.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	share.visible = false
	share.pressed.connect(func(): Sfx.play("tap"); share_daily(int(share.get_meta("stars", 3))))
	v.add_child(share)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	var levels := IconButton.new("grid", 96)
	levels.pressed.connect(func(): Sfx.play("tap"); overlay.visible = false; open_select())
	row.add_child(levels)
	var retry := IconButton.new("restart", 96)
	retry.pressed.connect(func(): Sfx.play("tap"); overlay.visible = false; start_level(current))
	row.add_child(retry)
	var next := IconButton.new("next", 120)
	next.name = "Next"
	next.tint = Palette.BG_TOP
	next.fill = Palette.ACCENT
	next.pressed.connect(_on_next)
	row.add_child(next)


# ---------------------------------------------------------------- layout

## Safe-area insets (notch, Dynamic Island, home indicator) in viewport units.
## Returns Rect2(left, top, right, bottom) packed as position=(left, top), size=(right, bottom).
## Only applied on native mobile; on web the browser already keeps content inside the safe area
## because the shell's viewport meta does not use viewport-fit=cover.
func safe_insets(view_size: Vector2) -> Rect2:
	if not OS.has_feature("mobile") or OS.has_feature("web"):
		return Rect2()
	var sa := DisplayServer.get_display_safe_area()
	var ws := Vector2(DisplayServer.window_get_size())
	if sa.size.x <= 0 or ws.x <= 0:
		return Rect2()
	var k := view_size / ws
	return Rect2(sa.position.x * k.x, sa.position.y * k.y, (ws.x - sa.end.x) * k.x, (ws.y - sa.end.y) * k.y)


func _layout() -> void:
	var s := size
	if s.x <= 0:
		s = get_viewport_rect().size
	var safe := safe_insets(s)
	var top := 24.0 + safe.position.y
	var back := screen_game.get_node("Back") as Control
	back.position = Vector2(24, top)
	lbl_level.position = Vector2(116, top)
	lbl_level.size = Vector2(s.x - 116 - 200, 84)
	lbl_level.clip_text = true
	gap_counter.position = Vector2(s.x - 24 - 150, top + 12)
	gap_counter.size = Vector2(150, 60)
	# Autowrap labels keep a stale tall height if they were ever laid out narrow
	# (e.g. the web canvas starts at 300x150), so reset width first, then height.
	lbl_tip.position = Vector2(40, top + 96)
	lbl_tip.custom_minimum_size = Vector2(maxf(100.0, s.x - 80), 0)
	lbl_tip.size = Vector2(maxf(100.0, s.x - 80), 0)
	lbl_tip.reset_size()
	var bottom_h := 190.0 + safe.size.y
	var by := s.y - bottom_h + 20
	var cx := s.x * 0.5
	btn_undo.position = Vector2(cx - 52 - 195, by)
	btn_restart.position = Vector2(cx - 52 - 65, by)
	btn_hint.position = Vector2(cx - 52 + 65, by)
	btn_help.position = Vector2(cx - 52 + 195, by)
	lbl_moves.position = Vector2(0, by + 112)
	lbl_moves.size = Vector2(s.x, 44)
	var board_rect := Rect2(Vector2(40, top + 190), Vector2(s.x - 80, by - (top + 190) - 40))
	board.fit(board_rect)
	var ow := minf(s.x - 48, 660)
	overlay.custom_minimum_size = Vector2(ow, 0)
	overlay.reset_size()
	overlay.position = Vector2((s.x - overlay.size.x) * 0.5, s.y - overlay.size.y - 32 - safe.size.y)


# ---------------------------------------------------------------- flow

func _refresh_daily_button() -> void:
	if btn_daily == null:
		return
	var day := Daily.day_number()
	btn_daily.text = tr("BTN_DAILY") % day
	btn_daily.visible = not Daily.puzzles().is_empty()
	var parts: PackedStringArray = []
	if save.daily_solved(day):
		parts.append(tr("LBL_DAILY_DONE"))
	var streak := save.current_streak(day)
	if streak > 0:
		parts.append(tr("LBL_STREAK") % streak)
	lbl_daily.text = "   ·   ".join(parts)
	lbl_daily.visible = not parts.is_empty()


func show_screen(sc: Control) -> void:
	if sc == screen_title:
		_refresh_daily_button()
	for x in [screen_title, screen_select, screen_game]:
		x.visible = x == sc
	board.interactive = sc == screen_game
	if sc != screen_game:
		overlay.visible = false


func open_select() -> void:
	_rebuild_select()
	show_screen(screen_select)


func _unlocked(n: int) -> bool:
	if not Entitlements.level_available(n):
		return false
	return n == 1 or save.is_done("level_%02d" % n) or save.is_done("level_%02d" % (n - 1))


func _next_unsolved() -> int:
	for n in range(1, LevelCatalog.COUNT + 1):
		if not save.is_done("level_%02d" % n):
			return n
	return LevelCatalog.COUNT


func start_level(n: int) -> void:
	var lv := LevelCatalog.load_level(n)
	if not lv.error.is_empty():
		push_error("level %d invalid: %s" % [n, lv.error])
		return
	current = n
	daily_day = 0
	_begin(lv, "%d · %s" % [n, lv.name], str(LevelCatalog.world_of(n).id), save.hotspots_for_level(n))


func start_daily() -> void:
	var day := Daily.day_number()
	var lv := Daily.level_for_day(day)
	if not lv.error.is_empty():
		push_error("daily invalid: %s" % lv.error)
		return
	daily_day = day
	current = 0
	_begin(lv, tr("BTN_DAILY") % day, "glassworks", str(save.settings.get("assist", "auto")) == "on")


func _begin(lv: LevelDefinition, title: String, world: String, hotspots: bool) -> void:
	hints_used = 0
	hint_key = ""
	music.play(world)
	game = PuzzleGame.new(lv)
	board.setup(game)
	overlay.visible = false
	win_pending = false
	lbl_level.text = title
	_show_tip(tr(lv.tutorial) if not lv.tutorial.is_empty() else "", false)
	board.show_hotspots = hotspots
	var first_encounter := lv.tutorial == "tut_drag" or lv.tutorial == "tut_motion"
	board.show_destinations = first_encounter
	if first_encounter:
		board.hint_move = PuzzleSolver.hint(lv, game.state)
	show_screen(screen_game)
	_layout()
	_layout.call_deferred()
	_refresh_hud()


func _refresh_hud() -> void:
	if game == null:
		return
	var par := game.level.par
	lbl_moves.text = "%s %d   ·   par %d" % [tr("LBL_MOVES"), game.moves, par]
	btn_undo.disabled = not game.can_undo()
	btn_undo.queue_redraw()
	gap_counter.counts = game.level.gap_totals(game.state.mat)
	gap_counter.queue_redraw()


func _show_tip(text: String, transient: bool) -> void:
	if tip_tween:
		tip_tween.kill()
	lbl_tip.text = text
	lbl_tip.modulate = Color(1, 1, 1, 1)
	if transient:
		# Show the message, then bring back the level's own tip (it used to vanish for good).
		var level_tip := ""
		if game != null and not game.level.tutorial.is_empty():
			level_tip = tr(game.level.tutorial)
		tip_tween = create_tween()
		tip_tween.tween_interval(2.2)
		tip_tween.tween_property(lbl_tip, "modulate:a", 0.0, 0.4)
		tip_tween.tween_callback(func(): lbl_tip.text = level_tip)
		tip_tween.tween_property(lbl_tip, "modulate:a", 1.0, 0.4)


func _on_transferred(_res: Dictionary) -> void:
	_refresh_hud()


func _on_board_settled() -> void:
	_refresh_hud()
	if game.is_solved() and not win_pending:
		win_pending = true
		board.interactive = false
		board.win_t = 0.0
		Sfx.play("win")
		var stars := save.record(game.level.id, game.moves, game.level.par, hints_used == 0)
		if daily_day > 0:
			save.levels.erase(game.level.id)   # dailies are tracked separately
			save.record_daily(daily_day, game.moves)
		save.save()
		var t := create_tween()
		t.tween_interval(0.9)
		t.tween_callback(_show_overlay.bind(stars))


func _show_overlay(stars: int) -> void:
	var share := overlay.get_node("V/Share") as Button
	share.visible = daily_day > 0
	share.set_meta("stars", stars)
	var w := LevelCatalog.world_of(maxi(current, 1))
	var dio := overlay.get_node("V/Dio") as Diorama
	dio.visible = daily_day == 0
	dio.world_id = w.id
	var flags: Array[bool] = []
	for n in range(w.first, w.last + 1):
		flags.append(save.is_done("level_%02d" % n))
	dio.restored = flags
	dio.highlight = current - w.first
	(overlay.get_node("V/Stars") as StarRow).stars = stars
	var info := "%s %d   ·   par %d" % [tr("LBL_MOVES"), game.moves, game.level.par]
	if hints_used == 0 and game.moves <= game.level.par:
		info += "\n" + tr("LBL_PERFECT")
	(overlay.get_node("V/Info") as Label).text = info
	overlay.visible = true
	_layout()
	var target_y := overlay.position.y
	overlay.position.y = size.y + 20
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(overlay, "position:y", target_y, 0.45)


func _on_next() -> void:
	Sfx.play("tap")
	overlay.visible = false
	if daily_day > 0:
		daily_day = 0
		show_screen(screen_title)
	elif current < LevelCatalog.COUNT and Entitlements.level_available(current + 1):
		start_level(current + 1)
	else:
		open_select()


func _on_undo() -> void:
	if board.is_busy():
		board.finish_animation()
	if win_pending:
		return
	if game.undo():
		Sfx.play("undo")
		board.sync_from_game()
		board.hint_move = Vector2i(-1, -1)
	_refresh_hud()


func _on_restart() -> void:
	if win_pending:
		return
	Sfx.play("undo", 0.8)
	game.restart()
	board.sync_from_game()
	_refresh_hud()


func _on_hint() -> void:
	if win_pending:
		return
	if board.is_busy():
		board.finish_animation()
	Sfx.play("tap")
	var mv := PuzzleSolver.hint(game.level, game.state)
	if mv.x < 0:
		_show_tip(tr("MSG_STUCK"), true)
		return
	hints_used += 1
	# Two stages per position: first only which gap to use, then where it goes.
	var key := game.state.key()
	if hint_key != key:
		hint_key = key
		board.hint_src = mv.x
		board.hint_move = Vector2i(-1, -1)
		_show_tip(tr("HINT_STAGE1"), true)
	else:
		board.hint_src = -1
		board.hint_move = mv


func _on_rejected(reason: String) -> void:
	if REASON_KEYS.has(reason):
		_show_tip(tr(REASON_KEYS[reason]), true)


## Desktop shortcuts (Steam / web with keyboard): Z or Ctrl+Z undo, R restart, H hint, Esc back.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if screen_game.visible and not overlay.visible:
		match k.keycode:
			KEY_Z:
				_on_undo()
			KEY_R:
				_on_restart()
			KEY_H:
				_on_hint()
			KEY_ESCAPE:
				open_select()
	elif overlay.visible and (k.keycode == KEY_ENTER or k.keycode == KEY_SPACE):
		_on_next()
	elif screen_select.visible and k.keycode == KEY_ESCAPE:
		show_screen(screen_title)



# ---------------------------------------------------------------- iOS touch fix
## Godot only emulates mouse clicks for touch index 0, but iOS Safari gives touches large
## identifiers, so buttons never received clicks. For a primary touch with a non-zero index we
## synthesize the (touch-emulated) mouse events ourselves, in viewport coordinates.
var _gui_touch := -1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _gui_touch == -1 and t.index != 0:
			_gui_touch = t.index
		if t.index != _gui_touch or t.index == 0:
			return
		var mb := InputEventMouseButton.new()
		mb.device = InputEvent.DEVICE_ID_EMULATION
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = t.pressed
		mb.button_mask = MOUSE_BUTTON_MASK_LEFT if t.pressed else 0
		mb.position = t.position
		mb.global_position = t.position
		if not t.pressed:
			_gui_touch = -1
		get_viewport().push_input.call_deferred(mb, true)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != _gui_touch or d.index == 0:
			return
		var mm := InputEventMouseMotion.new()
		mm.device = InputEvent.DEVICE_ID_EMULATION
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		mm.position = d.position
		mm.global_position = d.position
		mm.relative = d.relative
		get_viewport().push_input.call_deferred(mm, true)



# ---------------------------------------------------------------- how to play
func open_howto() -> void:
	board.interactive = false
	howto.open()


func _on_howto_closed() -> void:
	board.interactive = screen_game.visible and not win_pending



func _assist_label() -> String:
	return "%s: %s" % [tr("LBL_ASSIST"), tr("ASSIST_" + str(save.settings.get("assist", "auto")).to_upper())]



# ---------------------------------------------------------------- sharing
func share_daily(stars: int) -> String:
	var perfect := hints_used == 0 and game.moves <= game.level.par
	var text := Daily.share_text(daily_day, game.moves, game.level.par, stars, save.current_streak(daily_day), perfect)
	DisplayServer.clipboard_set(text)
	var shared := false
	if OS.has_feature("web"):
		# iOS/Android browsers: open the native share sheet when available.
		var res: Variant = JavaScriptBridge.eval("(function(t){ if (navigator.share) { navigator.share({text: t}).catch(function(){}); return 'share'; } return 'none'; })(%s)" % JSON.stringify(text), true)
		shared = str(res) == "share"
	if not shared:
		_show_tip(tr("MSG_COPIED"), true)
	return text
