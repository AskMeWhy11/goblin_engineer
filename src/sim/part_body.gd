class_name PartBody
extends RigidBody3D
## A live machine part. Part types extend this and override the hooks below.

enum State { OK, MALFUNCTIONED, DETACHED, DESTROYED }

var def: PartDef
var entry: BlueprintEntry
var tier: QualityTier
var state: State = State.OK
var machine: Machine
## -1..1, written by MachineController every physics tick.
var input_value := 0.0


## Still part of the machine's failure bookkeeping (may be cut off from the core).
func is_attached() -> bool:
	return state == State.OK or state == State.MALFUNCTIONED


func is_working() -> bool:
	return state == State.OK


## Base load for the failure clock: 1 while the part is loaded, 0 at rest.
func get_load() -> float:
	return 1.0 if def.always_loaded else 0.0


func set_input(value: float) -> void:
	input_value = value


## Called once when the part malfunctions. Types override this with their own effect.
func apply_malfunction() -> void:
	pass


## Short text for the failure log, e.g. "заглохло".
func malfunction_text() -> String:
	return "вышла из строя"


## Called after all joints of this part were removed.
func on_detached() -> void:
	pass


## A special joint (hinge, steering) between this part and `other`, already positioned in the
## machine's space, or null for the default rigid joint. node_a will be `other`, node_b this part.
func custom_joint_to(_other: PartBody) -> Joint3D:
	return null


## World direction of a local axis.
func world_axis(local: Vector3) -> Vector3:
	return (global_transform.basis * local).normalized()
