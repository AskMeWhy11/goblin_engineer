class_name DeliverCargoObjective
extends Objective
## Done when the level's "Cargo" body is within `radius` of this node.

@export var radius := 4.0

var _cargo: RigidBody3D
var _cargo_start: Transform3D
var _has_start := false


func _find_cargo() -> void:
	if _cargo == null:
		_cargo = get_parent().get_node_or_null("Cargo") as RigidBody3D
		if _cargo != null:
			_cargo_start = _cargo.global_transform
			_has_start = true


func _on_start() -> void:
	_find_cargo()


func _check() -> bool:
	if not is_instance_valid(_cargo):
		return false
	return _flat_distance(_cargo.global_position) <= radius and _cargo.global_position.y > global_position.y - 2.0


func _on_reset() -> void:
	_find_cargo()
	if is_instance_valid(_cargo) and _has_start:
		_cargo.global_transform = _cargo_start
		_cargo.linear_velocity = Vector3.ZERO
		_cargo.angular_velocity = Vector3.ZERO
