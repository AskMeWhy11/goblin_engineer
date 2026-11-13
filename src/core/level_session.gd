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
var build_mode: BuildMode
var build_hud: BuildHud
var sim_mode: SimMode
var sim_hud: SimHud

var _pause: PauseMenu


func _ready() -> void:
	level = Game.current_level if Game.current_level != null else Game.levels[0]
	blueprint = Game.blueprint_for(level)
	level_root = level.scene.instantiate()
	add_child(level_root)
	build_mode = BuildMode.new()
	add_child(build_mode)
	build_mode.setup(self)
	build_hud = BuildHud.new()
	add_child(build_hud)
	build_hud.setup(self, build_mode)
	sim_mode = SimMode.new()
	add_child(sim_mode)
	sim_mode.setup(self)
	sim_hud = SimHud.new()
	add_child(sim_hud)
	sim_hud.setup(self)
	sim_mode.machine_started.connect(sim_hud.track)
	_pause = PauseMenu.new()
	add_child(_pause)
	_apply_mode()


## "" when the current machine may launch, otherwise the reason.
func launch_blocker() -> String:
	return RiskCalculator.launch_blocker(RiskCalculator.evaluate(blueprint, PartCatalog.defs), level)


func enter_build() -> void:
	mode = Mode.BUILD
	sim_mode.stop()
	_apply_mode()
	mode_changed.emit(mode)


## seed < 0 picks a new random seed. Does nothing while the machine is not allowed to launch.
func enter_sim(seed: int = -1) -> void:
	if not launch_blocker().is_empty():
		return
	last_seed = seed if seed >= 0 else int(randi() & 0x7FFFFFFF)
	mode = Mode.SIM
	_apply_mode()
	sim_mode.start(last_seed)
	mode_changed.emit(mode)


func _apply_mode() -> void:
	build_mode.set_active(mode == Mode.BUILD)
	build_hud.visible = mode == Mode.BUILD
	sim_hud.visible = mode == Mode.SIM


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_sim"):
		if mode == Mode.BUILD:
			enter_sim()
		else:
			enter_build()
	elif event.is_action_pressed(&"repeat_seed") and last_seed >= 0:
		enter_sim(last_seed)
