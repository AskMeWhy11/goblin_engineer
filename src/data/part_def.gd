class_name PartDef
extends Resource
## Static description of a part type. Instances live in data/parts/*.tres (generated).

enum Activation { NONE, HOLD, PRESS }

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var base_price: int
@export var mass: float = 1.0
@export var tiers: Array[QualityTier]
@export var activation: Activation = Activation.NONE
## Passive parts accumulate risk from the moment of launch.
@export var always_loaded: bool
@export var default_key_positive: Key = KEY_NONE
@export var default_key_negative: Key = KEY_NONE
## Local normals of faces that accept a connection; empty means all six.
@export var attach_faces: Array[Vector3i]
## Explosion impulse in N*s; 0 means the part never explodes.
@export var explosion_power: float
@export var explosion_radius: float
@export var removable: bool = true


func price(tier: int) -> int:
	return roundi(base_price * tiers[tier].price_mult)
