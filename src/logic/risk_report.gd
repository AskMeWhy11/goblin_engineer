class_name RiskReport
extends RefCounted
## Result of RiskCalculator.evaluate: cost and raw failure-rate sums per mode.

var cost: int
var malfunction: float
var breakage: float
var explosion: float


## Machine risk in explosion-equivalents per second.
func total() -> float:
	return explosion * FailureMode.WEIGHTS[FailureMode.EXPLODE] \
			+ breakage * FailureMode.WEIGHTS[FailureMode.BREAK] \
			+ malfunction * FailureMode.WEIGHTS[FailureMode.MALFUNCTION]
