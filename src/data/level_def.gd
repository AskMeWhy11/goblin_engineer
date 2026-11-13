class_name LevelDef
extends Resource
## Static description of a level. Instances live in data/levels/*.tres.

@export var id: StringName
@export var title: String
@export var task_text: String
@export var scene: PackedScene
@export var budget: int
## Minimum machine risk in explosion-equivalents per second.
@export var risk_min: float
@export var allowed_parts: Array[StringName]
@export var volume_min: Vector3i
## Inclusive.
@export var volume_max: Vector3i
