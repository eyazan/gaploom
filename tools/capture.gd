extends SceneTree
## Captures gameplay screenshots by driving the real UI.
## Usage: xvfb-run godot -s tools/capture.gd --resolution 720x1280 -- <out_dir> [levels...]

var out := "res://reports/screenshots/"


func _initialize() -> void:
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out).path_join(name + ".png"))
	print("saved ", name)


func _wait(frames: int) -> void:
	# Frame counts are converted to wall-clock time (60 fps) so animations finish under any renderer speed.
	await create_timer(frames / 60.0).timeout


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var levels: Array[int] = []
	for i in range(1, args.size()):
		levels.append(int(args[i]))
	if levels.is_empty():
		levels = [1, 7, 12, 18, 20]
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _wait(40)
	main.show_screen(main.screen_title)
	await _wait(30)
	await _shot("00_title")
	for n in levels:
		main.start_level(n)
		await _wait(30)
		await _shot("level_%02d_a_start" % n)
		var sol: Array = PuzzleSolver.solve(main.game.level).solution
		for k in sol.size():
			var mv: Array = sol[k]
			if k == 0:
				main.board._select(mv[0])
				await _wait(10)
				await _shot("level_%02d_b_selected" % n)
				main.board._deselect()
			main.board.request_transfer(mv[0], mv[1])
			await _wait(45)
		await _wait(20)
		await _shot("level_%02d_c_solved" % n)
		await _wait(60)
		await _shot("level_%02d_d_overlay" % n)
	main.open_select()
	await _wait(30)
	await _shot("99_select")
	quit()
