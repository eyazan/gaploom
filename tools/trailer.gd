extends SceneTree
## Scripted ~25 s gameplay trailer for stores / short-form video.
## Record: xvfb-run -a godot --write-movie build/trailer.avi --fixed-fps 30 --resolution 720x1280 -s tools/trailer.gd
## Then:   ffmpeg -i build/trailer.avi -vf scale=1080:1920:flags=lanczos -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac build/trailer.mp4

var main: Control


func _initialize() -> void:
	_run()


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _play_solution(n: int, gap_s: float) -> void:
	main.start_level(n)
	await _wait(1.0)
	var b: BoardView = main.board
	var sol: Array = PuzzleSolver.solve(main.game.level).solution
	for mv in sol:
		b.hint_move = Vector2i(mv[0], mv[1])
		await _wait(0.9)
		b.hint_move = Vector2i(-1, -1)
		b._select(mv[0])
		await _wait(0.25)
		b._deselect()
		b.request_transfer(mv[0], mv[1])
		await _wait(gap_s)
	await _wait(2.2)


func _run() -> void:
	TranslationServer.set_locale(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "en")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _wait(0.3)
	main.show_screen(main.screen_title)
	await _wait(3.4)
	await _play_solution(1, 1.0)
	await _play_solution(18, 1.2)
	await _play_solution(28, 0.9)
	main.overlay.visible = false
	main.show_screen(main.screen_title)
	await _wait(3.0)
	quit()
