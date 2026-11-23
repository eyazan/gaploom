extends SceneTree
## Screenshot of the rejection visuals (split on level 4, not-reached on level 8).
func _initialize() -> void:
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/screenshots/").path_join(name + ".png"))


func _run() -> void:
	TranslationServer.set_locale("tr")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	main.start_level(4)
	await create_timer(0.4).timeout
	var b: BoardView = main.board
	var lv: LevelDefinition = main.game.level
	b._select(lv.idx(1, 4))
	b._reject_at(lv.idx(2, 1))
	b._deselect()
	await create_timer(0.25).timeout
	await _shot("reject_split")
	main.start_level(8)
	await create_timer(0.4).timeout
	lv = main.game.level
	b._select(lv.idx(0, 6))
	b._reject_at(lv.idx(2, 3))
	b._deselect()
	await create_timer(0.25).timeout
	await _shot("reject_not_reached")
	quit()
