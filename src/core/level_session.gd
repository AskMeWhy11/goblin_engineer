class_name LevelSession
extends Node3D
## Root of a played level: owns the level scene and switches between build and simulation.

enum Mode { BUILD, SIM }

signal mode_changed(mode: Mode)

var mode: Mode = Mode.BUILD
var level: LevelDef
var level_root: Node3D
var blueprint: Blueprint
var last_seed: int = -1

var _pause: PauseMenu
var _mode_label: Label


func _ready() -> void:
	level = Game.current_level if Game.current_level != null else Game.levels[0]
	blueprint = Game.blueprint_for(level)
	level_root = level.scene.instantiate()
	add_child(level_root)
	_pause = PauseMenu.new()
	add_child(_pause)
	var hud := CanvasLayer.new()
	add_child(hud)
	_mode_label = UiKit.label(hud, "", 18, Color(1, 1, 1, 0.6))
	_mode_label.position = Vector2(12, 8)
	_apply_mode()


func enter_build() -> void:
	mode = Mode.BUILD
	_apply_mode()
	mode_changed.emit(mode)


## seed < 0 picks a new random seed.
func enter_sim(seed: int = -1) -> void:
	last_seed = seed if seed >= 0 else int(randi() & 0x7FFFFFFF)
	mode = Mode.SIM
	_apply_mode()
	mode_changed.emit(mode)


func _apply_mode() -> void:
	_mode_label.text = "Сборка" if mode == Mode.BUILD else "Запуск"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_sim"):
		if mode == Mode.BUILD:
			enter_sim()
		else:
			enter_build()
	elif event.is_action_pressed(&"repeat_seed") and last_seed >= 0:
		enter_sim(last_seed)
