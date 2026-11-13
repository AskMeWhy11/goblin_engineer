extends PartBody
## The core: the test pilot's seat. Never fails by itself; hard hits on it hurt the pilot.

var pilot: Pilot

var _age := 0.0
var _last_velocity := Vector3.ZERO
var _has_last := false
var _skip_impact := false


func _ready() -> void:
	pilot = Pilot.new()
	pilot.name = "Pilot"
	add_child(pilot)


## The next velocity jump comes from a blast that already dealt its own damage.
func skip_next_impact() -> void:
	_skip_impact = true


func _physics_process(delta: float) -> void:
	_age += delta
	var velocity := linear_velocity
	if _has_last and not _skip_impact and _age > SimTuning.SHAKE_GRACE:
		pilot.take_damage(Pilot.impact_damage((velocity - _last_velocity).length()))
	_skip_impact = false
	_last_velocity = velocity
	_has_last = true
	if global_position.y < SimTuning.KILL_Y:
		pilot.take_damage(pilot.health)
