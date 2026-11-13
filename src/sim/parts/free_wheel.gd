class_name FreeWheel
extends PartBody
## A wheel on a hinge. The axle is the part's local X axis (the mount face looks along -X).

var _hinge: HingeJoint3D
var _jammed := false


func custom_joint_to(_other: PartBody) -> Joint3D:
	var axis := transform.basis.x.normalized()
	var up := Vector3.RIGHT if absf(axis.y) > 0.9 else Vector3.UP
	_hinge = HingeJoint3D.new()
	# Godot hinges rotate around the joint's local Z axis.
	_hinge.transform = Transform3D(Basis.looking_at(-axis, up), position)
	_configure_hinge()
	return _hinge


func _configure_hinge() -> void:
	pass


func apply_malfunction() -> void:
	_jammed = true
	_brake()


func malfunction_text() -> String:
	return "заклинило"


## Holds the wheel still with the hinge motor.
func _brake() -> void:
	if is_instance_valid(_hinge):
		_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
		_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, SimTuning.WHEEL_BRAKE_IMPULSE)
