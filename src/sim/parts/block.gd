extends PartBody
## Structural block. Malfunction: its rigid joints get angular play.


func apply_malfunction() -> void:
	for joint in machine.joints_of(self):
		if not (joint is Generic6DOFJoint3D):
			continue
		var loose := Generic6DOFJoint3D.new()
		var play := SimTuning.LOOSE_JOINT_PLAY
		loose.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -play)
		loose.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, play)
		loose.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -play)
		loose.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, play)
		loose.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -play)
		loose.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, play)
		machine.replace_joint(joint, loose)


func malfunction_text() -> String:
	return "разболтался"
