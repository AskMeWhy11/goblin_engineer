class_name QualityTier
extends Resource
## One quality level of a part: cheaper tiers fail more often and have less strength margin.

@export var display_name: String
@export var price_mult: float = 1.0
## Failure rates per second at load 1: x malfunction, y break, z explode.
@export var rates: Vector3
## Strength margin S (design doc 6.3): how much shock above normal load the part tolerates.
@export var strength_margin: float = 1.0
