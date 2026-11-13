extends PartBody
## Powder barrel: a bomb set off by its key. Explodes on its own often enough.

var _damp := false
var _was_pressed := false


func _physics_process(_delta: float) -> void:
	var pressed := input_value > 0.0
	if pressed and not _was_pressed and not _damp:
		machine.explode(self)
	_was_pressed = pressed


func detonates_in_chain() -> bool:
	return true


func apply_malfunction() -> void:
	_damp = true


func malfunction_text() -> String:
	return "отсырела"
