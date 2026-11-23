extends SceneTree
## Renders level files to PNG (board only) for visual review.
## Usage: xvfb-run -a godot -s tools/render_levels.gd --resolution 540x700 -- <out_dir> a.json b.json ...

func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var bg := ColorRect.new()
	bg.color = Palette.BG_TOP
	bg.size = Vector2(540, 700)
	root.add_child(bg)
	var v := BoardView.new()
	v.silent = true
	root.add_child(v)
	var label := Label.new()
	label.position = Vector2(10, 650)
	label.add_theme_font_size_override("font_size", 22)
	root.add_child(label)
	for i in range(1, args.size()):
		var lv := LevelDefinition.load_file(args[i])
		if not lv.error.is_empty():
			print("invalid ", args[i])
			continue
		var g := PuzzleGame.new(lv)
		v.setup(g)
		v.fit(Rect2(Vector2(20, 20), Vector2(500, 610)))
		label.text = args[i].get_file() + "  par " + str(lv.par)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(out.path_join(args[i].get_file().get_basename() + ".png"))
	quit()
