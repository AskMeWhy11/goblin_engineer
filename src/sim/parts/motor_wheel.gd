extends FreeWheel
## A driven wheel. Positive input drives the machine towards its build-time +X.

enum Fault { NONE, STALLED, STUCK }

var _fault := Fault.NONE
var _stuck_value := 1.0
var _last_nonzero := 0.0
## +1 or -1: converts "forward" into this wheel's hinge direction (left and right wheels mirror).
var _forward_sign := 1.0


func _configure_hinge() -> void:
	# A wheel rolling towards +X spins around UP x FORWARD = -Z.
	var along := transform.basis.x.normalized().dot(Vector3.UP.cross(Vector3.RIGHT))
	_forward_sign = -1.0 if along < -0.01 else 1.0
	_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, SimTuning.MOTOR_MAX_IMPULSE)
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)


func set_input(value: float) -> void:
	super(value)
	if value != 0.0:
		_last_nonzero = value


func _drive() -> float:
	match _fault:
		Fault.STALLED:
			return 0.0
		Fault.STUCK:
			return _stuck_value
	return input_value


func get_load() -> float:
	return absf(_drive())


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_hinge) or _fault == Fault.STALLED:
		return
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY,
			_drive() * SimTuning.MOTOR_SPEED * _forward_sign * SimTuning.HINGE_MOTOR_SIGN)


func apply_malfunction() -> void:
	if machine.rng.randf() < 0.5:
		_fault = Fault.STALLED
		if is_instance_valid(_hinge):
			_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
	else:
		_fault = Fault.STUCK
		_stuck_value = _last_nonzero if _last_nonzero != 0.0 else 1.0


func malfunction_text() -> String:
	return "заглохло" if _fault == Fault.STALLED else "залипло на газу"
