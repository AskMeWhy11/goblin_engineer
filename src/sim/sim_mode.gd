class_name SimMode
extends Node3D
## Simulation mode: builds the machine from the blueprint and tears it down on exit.

signal machine_started(machine: Machine)

var machine: Machine
var camera: OrbitCamera
var controller: MachineController
var failures: FailureSystem

var _session: LevelSession


func setup(session: LevelSession) -> void:
	_session = session
	camera = OrbitCamera.new()
	camera.extra_drag_button = MOUSE_BUTTON_RIGHT
	camera.distance = 16.0
	camera.yaw = 0.9
	add_child(camera)


func start(seed: int) -> void:
	stop()
	var marker := _session.level_root.get_node_or_null("BuildOrigin") as Node3D
	var origin := marker.global_position if marker != null else Vector3.ZERO
	machine = MachineAssembler.build(_session.blueprint, PartCatalog.defs, Transform3D(Basis.IDENTITY, origin))
	machine.rng.seed = seed
	add_child(machine)
	controller = MachineController.new()
	controller.machine = machine
	machine.add_child(controller)
	failures = FailureSystem.new()
	machine.add_child(failures)
	failures.setup(machine, seed)
	machine.part_failed.connect(_show_failure)
	var active_controller := controller
	machine.pilot().died.connect(func() -> void: active_controller.enabled = false)
	camera.target = machine.core()
	camera.pivot = origin
	camera.make_current()
	camera.update_transform()
	machine_started.emit(machine)


## Frees the machine and everything it spawned (timers, projectiles live under it).
func stop() -> void:
	if machine != null:
		camera.target = null
		machine.free()
		machine = null
		controller = null
		failures = null


## Tints the failed part for a second and floats a caption above it for two.
func _show_failure(part: PartBody, mode: int, _time: float) -> void:
	var color := SimHud.failure_color(mode)
	var caption := Label3D.new()
	caption.text = "%s: %s" % [part.def.display_name, SimHud.failure_text(part, mode)]
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = true
	caption.fixed_size = true
	caption.pixel_size = 0.0018
	caption.font_size = 40
	caption.outline_size = 10
	caption.modulate = color
	machine.add_child(caption)
	caption.global_position = part.global_position + Vector3(0, 1.2, 0)
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(caption):
			caption.queue_free())
	if part.state == PartBody.State.DESTROYED:
		return
	PartVisuals.set_overlay(part, Color(color, 0.6))
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(part):
			PartVisuals.set_overlay(part, Color.TRANSPARENT))
