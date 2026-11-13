class_name Pilot
extends Node
## The goblin test pilot riding in the core. Death means loss of control, not defeat.

signal health_changed(value: float)
signal died

const MAX_HEALTH := 100.0

var health := MAX_HEALTH


func is_alive() -> bool:
	return health > 0.0


func take_damage(amount: float) -> void:
	if amount <= 0.0 or not is_alive():
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		died.emit()


## Damage from an explosion of impulse `power` and `radius` at `distance` from the pilot.
static func explosion_damage(power: float, radius: float, distance: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	return power * (1.0 - distance / radius) * SimTuning.PILOT_BLAST_DAMAGE


## Damage from the cabin's velocity changing by `delta_speed` m/s within one physics tick.
static func impact_damage(delta_speed: float) -> float:
	return maxf(0.0, delta_speed - SimTuning.PILOT_IMPACT_FREE) * SimTuning.PILOT_IMPACT_DAMAGE
