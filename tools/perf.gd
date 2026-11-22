extends SceneTree
## Measures startup-to-ready, frame time while animating, and memory.
## Usage: xvfb-run godot -s tools/perf.gd --resolution 720x1280

func _initialize() -> void:
	_run()


func _run() -> void:
	var t_start := Time.get_ticks_msec()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var t_ready := Time.get_ticks_msec()
	var results := {"process_ticks_at_script_start_ms": t_start, "main_ready_after_ms": t_ready - t_start, "renderer": RenderingServer.get_video_adapter_name()}
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for n in [1, 10, 20]:
		main.start_level(n)
		var b: BoardView = main.board
		var sol: Array = PuzzleSolver.solve(main.game.level).solution
		var frames := 0
		var worst := 0.0
		var t0 := Time.get_ticks_usec()
		var last := t0
		var k := 0
		while Time.get_ticks_usec() - t0 < 3000000:
			await process_frame
			frames += 1
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
			if not b.is_busy() and k < sol.size() and frames % 40 == 0:
				b.request_transfer(sol[k][0], sol[k][1])
				k += 1
		var secs := (Time.get_ticks_usec() - t0) / 1000000.0
		results["level_%02d" % n] = {
			"avg_fps_uncapped": snappedf(frames / secs, 0.1),
			"avg_frame_ms": snappedf(secs * 1000.0 / frames, 0.01),
			"worst_frame_ms": snappedf(worst, 0.01),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		}
	results["static_memory_mb"] = snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01)
	results["static_memory_peak_mb"] = snappedf(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0, 0.01)
	results["video_memory_mb"] = snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.01)
	var f := FileAccess.open("res://reports/performance_raw.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(results, " "))
	print(JSON.stringify(results, " "))
	quit()
