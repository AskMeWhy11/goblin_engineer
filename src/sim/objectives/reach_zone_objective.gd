class_name ReachZoneObjective
extends Objective
## Done when the core is within `radius` of this node (a living pilot is not required).

@export var radius := 4.0


func _check() -> bool:
	if not is_instance_valid(_machine):
		return false
	var core := _machine.core()
	return core != null and _flat_distance(core.global_position) <= radius
