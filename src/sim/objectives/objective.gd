class_name Objective
extends Node3D
## Base class of a level goal. Lives in the level scene as the node "Objective".

signal completed

var is_completed := false

var _machine: Machine


func _ready() -> void:
	set_physics_process(false)


## Called when the simulation starts.
func start(machine: Machine) -> void:
	_machine = machine
	is_completed = false
	_on_start()
	set_physics_process(true)


## Called when the player returns to build mode: puts the level back as it was.
func reset() -> void:
	set_physics_process(false)
	_machine = null
	is_completed = false
	_on_reset()


func _physics_process(_delta: float) -> void:
	if not is_completed and _check():
		is_completed = true
		completed.emit()


func _check() -> bool:
	return false


func _on_start() -> void:
	pass


func _on_reset() -> void:
	pass


## Horizontal distance from this node to a world position.
func _flat_distance(point: Vector3) -> float:
	var d := point - global_position
	return Vector2(d.x, d.z).length()
