class_name SimMode
extends Node3D
## Simulation mode: builds the machine from the blueprint and tears it down on exit.

signal machine_started(machine: Machine)

var machine: Machine
var camera: OrbitCamera
var controller: MachineController
var failures: FailureSystem
var objective: Objective
var sfx: Sfx

var _session: LevelSession


func setup(session: LevelSession) -> void:
	_session = session
	objective = session.level_root.get_node_or_null("Objective") as Objective
	sfx = Sfx.new()
	add_child(sfx)
	if objective != null:
		objective.completed.connect(sfx.play.bind(&"win"))
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
	machine.exploded.connect(_show_explosion)
	machine.sound_requested.connect(func(kind: StringName) -> void: sfx.play(kind))
	var active_controller := controller
	machine.pilot().died.connect(func() -> void: active_controller.enabled = false)
	camera.target = machine.core()
	camera.pivot = origin
	camera.make_current()
	camera.update_transform()
	if objective != null:
		objective.start(machine)
	machine_started.emit(machine)


## Frees the machine and everything it spawned (timers, projectiles live under it).
func stop() -> void:
	if machine != null:
		camera.target = null
		machine.free()
		machine = null
		controller = null
		failures = null
		if objective != null:
			objective.reset()


## Fireball sized by the blast radius, sound louder for stronger blasts.
func _show_explosion(at: Vector3, power: float, radius: float) -> void:
	Fx.explosion(machine, at, radius)
	sfx.play(&"explode", clampf(linear_to_db(power / 2500.0), -14.0, 0.0))


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
	machine.after(2.0, caption.queue_free)
	if mode == FailureMode.MALFUNCTION:
		Fx.smoke(part)
		sfx.play(&"malfunction", -6.0)
	elif mode == FailureMode.BREAK:
		sfx.play(&"break")
	if part.state == PartBody.State.DESTROYED:
		return
	PartVisuals.set_overlay(part, Color(color, 0.6))
	machine.after(1.0, PartVisuals.set_overlay.bind(part, Color.TRANSPARENT))
