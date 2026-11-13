class_name SimMode
extends Node3D
## Simulation mode: builds the machine from the blueprint and tears it down on exit.

signal machine_started(machine: Machine)

var machine: Machine
var camera: OrbitCamera

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
