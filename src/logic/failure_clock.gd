class_name FailureClock
extends RefCounted
## Strength thresholds with fatigue (design doc 6.3). Knows nothing about nodes.
##
## For each (part, mode) with rate L > 0:  T0 = 1 + S * E,  E ~ Exp(1);
## each tick T -= S * L * load * dt; the mode fires when load >= T.
## At constant load 1 this gives exactly rate L failures per second.

var _rng := RandomNumberGenerator.new()
## key -> { rates: Vector3, margin: float, thresholds: Array[float] } (INF = mode disabled)
var _parts: Dictionary = {}


func _init(seed: int) -> void:
	_rng.seed = seed


func register(key: int, rates: Vector3, margin: float) -> void:
	var thresholds: Array[float] = []
	for mode in 3:
		if rates[mode] > 0.0:
			thresholds.append(1.0 + margin * -log(1.0 - _rng.randf()))
		else:
			thresholds.append(INF)
	_parts[key] = {rates = rates, margin = margin, thresholds = thresholds}


func is_registered(key: int) -> bool:
	return _parts.has(key)


## Advances fatigue and returns the heaviest FailureMode that fired, or FailureMode.NONE.
func tick(key: int, load: float, dt: float) -> int:
	var part: Dictionary = _parts.get(key, {})
	if part.is_empty():
		return FailureMode.NONE
	var thresholds: Array[float] = part.thresholds
	var rates: Vector3 = part.rates
	var margin: float = part.margin
	var fired := FailureMode.NONE
	for mode in 3:
		if thresholds[mode] == INF:
			continue
		thresholds[mode] -= margin * rates[mode] * load * dt
		if load > 0.0 and load >= thresholds[mode]:
			fired = mode
	if fired == FailureMode.MALFUNCTION:
		thresholds[FailureMode.MALFUNCTION] = INF
	elif fired != FailureMode.NONE:
		_parts.erase(key)
	return fired
