class_name HowTo
extends Control
## "How to play": one rule per page, each demonstrated by a small self-playing board.
## The demo plays the solver's optimal solution in a loop (ghost hand, then the move).

signal closed

const PAGES := [
	{"title": "HOW_T1", "text": "HOW_1", "rows": [
		".. .. ao .. ..",
		"E> .. ao .. R.",
		".. .. .. .. ..",
		".. bL bo .. .."]},
	{"title": "HOW_T2", "text": "HOW_2", "rows": [
		".. .. ao .. bo .. ..",
		"E> .. ao .. bo .. R.",
		".. .. .. .. .. .. ..",
		".. .. cL co cL .. .."]},
	{"title": "HOW_T3", "text": "HOW_3", "rows": [
		".. .. .. .. .. ..",
		"S> .. ao .. .. D.",
		".. .. ao .. .. ..",
		".. bM bo .. .. .."]},
	{"title": "HOW_T4", "text": "HOW_4", "rows": [
		"E> .. ao .. .. ..",
		"E> .. ao .. .. R.",
		".. .. ao .. .. ..",
		".. bL bo bL .. .."]},
	{"title": "HOW_T5", "text": "HOW_5", "rows": [
		".. .. .. .. Sv .. ..",
		"E> s> .. ao .. .. D.",
		".. .. .. ao .. .. ..",
		"gL go .. .. bo bo ..",
		".. .. hM .. .. .. ..",
		".. .. ho .. D. .. .."]},
	{"title": "HOW_T6", "text": "HOW_6", "rows": [
		".. .. .. Ev .. ..",
		".. .. .. xo xo ..",
		".. .. .. .. .. ..",
		"E> .. qo qo .. R.",
		".. .. qo .. .. ..",
		".. .. qo .. .. gL",
		".. .. .. .. gL go"]},
]

var page := 0
var board: BoardView
var game: PuzzleGame
var solution: Array = []
var step := 0
var phase_t := 0.0
var lbl_title: Label
var lbl_text: Label
var lbl_page: Label
var btn_prev: IconButton
var btn_next: IconButton
var btn_close: IconButton
var board_rect := Rect2()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Palette.BG_TOP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	board = BoardView.new()
	board.interactive = false
	board.silent = true
	add_child(board)
	lbl_title = _label(36)
	lbl_text = _label(30)
	lbl_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl_text.add_theme_color_override("font_color", Palette.TEXT)
	lbl_page = _label(26)
	lbl_page.add_theme_color_override("font_color", Palette.TEXT_DIM)
	btn_prev = IconButton.new("back", 96)
	btn_prev.pressed.connect(func(): show_page(page - 1))
	add_child(btn_prev)
	btn_next = IconButton.new("next", 110)
	btn_next.fill = Palette.ACCENT
	btn_next.tint = Palette.BG_TOP
	btn_next.pressed.connect(func():
		if page >= PAGES.size() - 1:
			close()
		else:
			show_page(page + 1))
	add_child(btn_next)
	btn_close = IconButton.new("close", 84)
	btn_close.pressed.connect(close)
	add_child(btn_close)
	resized.connect(_layout)
	show_page(0)


func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func open() -> void:
	visible = true
	show_page(0)
	_layout.call_deferred()


func close() -> void:
	visible = false
	Sfx.play("tap")
	closed.emit()


func show_page(i: int) -> void:
	page = clampi(i, 0, PAGES.size() - 1)
	var p: Dictionary = PAGES[page]
	var lv := LevelDefinition.from_dict({"id": "howto_%d" % page, "rows": p.rows})
	game = PuzzleGame.new(lv)
	board.setup(game)
	solution = PuzzleSolver.solve(lv).solution
	step = 0
	phase_t = 0.0
	lbl_title.text = tr(p.title)
	lbl_text.text = tr(p.text)
	lbl_page.text = "%d / %d" % [page + 1, PAGES.size()]
	btn_prev.disabled = page == 0
	btn_prev.queue_redraw()
	_layout()


func _layout() -> void:
	var s := size
	if s.x <= 0:
		return
	btn_close.position = Vector2(s.x - 24 - 84, 24)
	lbl_title.position = Vector2(116, 34)
	lbl_title.size = Vector2(s.x - 232, 64)
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var text_top := s.y * 0.56
	board_rect = Rect2(Vector2(48, 130), Vector2(s.x - 96, text_top - 150))
	board.fit(board_rect)
	lbl_text.position = Vector2(48, text_top)
	lbl_text.custom_minimum_size = Vector2(s.x - 96, 0)
	lbl_text.size = Vector2(s.x - 96, 0)
	lbl_text.reset_size()
	var by := s.y - 170
	btn_prev.position = Vector2(s.x * 0.5 - 48 - 120, by)
	btn_next.position = Vector2(s.x * 0.5 - 55 + 110, by - 7)
	lbl_page.position = Vector2(0, by + 112)
	lbl_page.size = Vector2(s.x, 40)


## Demo loop: show the ghost hand for a move, perform it, repeat; pause on the solved board, restart.
func _process(delta: float) -> void:
	if not visible or game == null:
		return
	phase_t += delta
	if board.is_busy():
		return
	if step >= solution.size():
		board.hint_move = Vector2i(-1, -1)
		if phase_t > 1.8:
			game.restart()
			board.sync_from_game()
			step = 0
			phase_t = 0.0
		return
	var mv: Array = solution[step]
	board.hint_move = Vector2i(mv[0], mv[1])
	if phase_t > 1.9:
		board.hint_move = Vector2i(-1, -1)
		board.request_transfer(mv[0], mv[1])
		step += 1
		phase_t = 0.0


func _gui_input(event: InputEvent) -> void:
	# Swallow taps so the board underneath never receives them.
	accept_event()
