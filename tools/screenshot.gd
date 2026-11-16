extends Node
## Opens a scene in a real window, waits, saves a PNG and quits. Run through tools/screenshot.ps1.
## Env: SHOT_SCENE (res:// path), SHOT_OUT (file path), SHOT_FRAMES (default 30),
##      SHOT_LEVEL (level id for Game.current_level), SHOT_SETUP (res:// script with
##      `static func setup(scene: Node) -> void`, may be a coroutine).


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var level_id := OS.get_environment("SHOT_LEVEL")
	for level in Game.levels:
		if String(level.id) == level_id:
			Game.current_level = level
	var scene: Node = load(OS.get_environment("SHOT_SCENE")).instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	var setup_path := OS.get_environment("SHOT_SETUP")
	if not setup_path.is_empty():
		await load(setup_path).setup(scene)
	var frames := int(OS.get_environment("SHOT_FRAMES")) if OS.has_environment("SHOT_FRAMES") else 30
	for _i in frames:
		await get_tree().process_frame
	print("SHOT fps=%d draw_calls=%d primitives=%d frame_ms=%.2f" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
	print("SHOT saved ", OS.get_environment("SHOT_OUT"))
	get_tree().quit()
