extends SceneTree
## App Store screenshots. Usage:
## xvfb-run -a -s "-screen 0 1290x2796x24" godot -s tools/store_shots.gd --resolution 1290x2796 -- <locale> <out_dir>

var main: Control
var out := ""


func _initialize() -> void:
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("saved ", name)


func _solve_partly(n: int, keep_last: int) -> void:
	main.start_level(n)
	await create_timer(0.6).timeout
	var sol: Array = PuzzleSolver.solve(main.game.level).solution
	for i in maxi(0, sol.size() - keep_last):
		main.board.request_transfer(sol[i][0], sol[i][1])
		await create_timer(0.1).timeout
		main.board.finish_animation()
	await create_timer(1.2).timeout


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	TranslationServer.set_locale(a[0] if a.size() > 0 else "en")
	out = a[1] if a.size() > 1 else ProjectSettings.globalize_path("res://docs/marketing/media/store")
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	main.show_screen(main.screen_title)
	await create_timer(2.0).timeout
	await _shot("1_title")
	await _solve_partly(28, 0)
	main.overlay.visible = false
	main.board.win_t = -1.0
	await create_timer(0.4).timeout
	await _shot("2_colours_solved")
	await _solve_partly(18, 1)
	await _shot("3_airlock")
	main.open_howto()
	main.howto.show_page(5)
	await create_timer(2.5).timeout
	await _shot("4_howto")
	main.howto.visible = false
	for n in range(1, 25):
		main.save.record("level_%02d" % n, 3, 3, true)
	main.open_select()
	await create_timer(1.0).timeout
	await _shot("5_worlds")
	quit()
