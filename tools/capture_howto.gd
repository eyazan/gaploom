extends SceneTree
## Screenshots of every How-to page. Usage: xvfb-run -a godot -s tools/capture_howto.gd --resolution 720x1280 -- <locale> <out_dir>

func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	TranslationServer.set_locale(args[0] if args.size() > 0 else "tr")
	var out := args[1] if args.size() > 1 else "res://reports/screenshots/"
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	main.open_howto()
	for i in HowTo.PAGES.size():
		main.howto.show_page(i)
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out).path_join("howto_%d.png" % (i + 1)))
	print("done")
	quit()
