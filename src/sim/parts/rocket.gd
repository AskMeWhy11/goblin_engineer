extends PartBody
## Rocket: pushes along its local +Z (the white tip) while the key is held.

var _dead := false
var _flame: Node3D


func _ready() -> void:
	_flame = Fx.rocket_flame(self)


func is_firing() -> bool:
	return not _dead and is_attached() and input_value > 0.0


func get_load() -> float:
	return 1.0 if is_firing() else 0.0


func _physics_process(_delta: float) -> void:
	_flame.visible = is_firing()
	if is_firing():
		apply_central_force(world_axis(Vector3.BACK) * SimTuning.ROCKET_THRUST)


func apply_malfunction() -> void:
	_dead = true


func malfunction_text() -> String:
	return "потухла"
