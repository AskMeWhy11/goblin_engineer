class_name FailureSystem
extends Node
## Feeds part loads into the FailureClock every physics tick and applies the failures it reports.

var _machine: Machine
var _clock: FailureClock
var _keys: Dictionary = {}  # PartBody -> int
var _time := 0.0


## Registers parts in machine.parts order, so the same seed gives the same thresholds.
func setup(machine: Machine, seed: int) -> void:
	_machine = machine
	_clock = FailureClock.new(seed)
	for i in machine.parts.size():
		var part := machine.parts[i]
		_keys[part] = i
		_clock.register(i, part.tier.rates, part.tier.strength_margin)


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if _machine == null:
		return
	_time += delta
	var shake_counts := _time > SimTuning.SHAKE_GRACE
	for part in _machine.attached_parts():
		# Always measured so the velocity history stays current; ignored while the machine settles.
		var shake := part.measure_shake(delta)
		if not part.is_attached():
			continue  # an earlier explosion in this tick tore it off
		var load := part.get_load() + (shake if shake_counts else 0.0)
		var mode := _clock.tick(_keys[part], load, delta)
		if mode != FailureMode.NONE:
			_machine.apply_failure(part, mode)
