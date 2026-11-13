class_name Destructible
extends RigidBody3D
## A piece of a target structure: destroyed by enough blast, or "down" when knocked off its place.

const DOWN_DISTANCE := 1.5

@export var toughness := 300.0

var is_destroyed := false

var _damage := 0.0
var _start: Transform3D
var _start_frozen := false
var _start_layer := 1
var _start_mask := 1


func _ready() -> void:
	add_to_group(&"destructible")
	remember_start()


## Records the current pose as the one `reset` returns to.
func remember_start() -> void:
	_start = global_transform
	_start_frozen = freeze
	_start_layer = collision_layer
	_start_mask = collision_mask


## `impulse` is the blast strength that reached this piece.
func take_hit(impulse: float) -> void:
	if is_destroyed:
		return
	_damage += impulse
	if _damage >= toughness:
		is_destroyed = true
		visible = false
		collision_layer = 0
		collision_mask = 0
		freeze = true


func is_down() -> bool:
	return is_destroyed or global_position.distance_to(_start.origin) > DOWN_DISTANCE


func reset() -> void:
	is_destroyed = false
	_damage = 0.0
	visible = true
	collision_layer = _start_layer
	collision_mask = _start_mask
	freeze = _start_frozen
	global_transform = _start
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
