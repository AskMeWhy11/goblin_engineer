extends PartBody
## Steering hinge: mounted by its base face (-X), turns everything else attached to it
## around its local Y axis by up to STEER_LIMIT.

var _hinge: HingeJoint3D
var _base: PartBody
var _rest: Basis
var _locked := false


func custom_joint_to(other: PartBody) -> Joint3D:
	var to_other := Vector3(other.entry.cell - entry.cell)
	var base_dir := (transform.basis * Vector3(def.base_face)).normalized()
	if to_other.dot(base_dir) < 0.9:
		return null
	_base = other
	_rest = other.transform.basis.inverse() * transform.basis
	var axis := transform.basis.y.normalized()
	var up := Vector3.RIGHT if absf(axis.y) > 0.9 else Vector3.UP
	_hinge = HingeJoint3D.new()
	_hinge.transform = Transform3D(Basis.looking_at(-axis, up), position)
	_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	_hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -SimTuning.STEER_LIMIT)
	_hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, SimTuning.STEER_LIMIT)
	_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, SimTuning.STEER_MAX_IMPULSE)
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	return _hinge


## Current steering angle in radians around the hinge axis; 0 = as built.
func current_angle() -> float:
	if not is_instance_valid(_base):
		return 0.0
	var now := _base.global_transform.basis.inverse() * global_transform.basis
	return (_rest.inverse() * now).get_euler().y


func get_load() -> float:
	return 0.0 if _locked else absf(input_value)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_hinge) or not is_instance_valid(_base):
		return
	var target := 0.0 if _locked else input_value * SimTuning.STEER_LIMIT
	var speed := 0.0 if _locked else clampf((target - current_angle()) * SimTuning.STEER_GAIN,
			-SimTuning.STEER_SPEED, SimTuning.STEER_SPEED)
	_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, speed * SimTuning.HINGE_MOTOR_SIGN)


func apply_malfunction() -> void:
	_locked = true


func malfunction_text() -> String:
	return "заклинил"
