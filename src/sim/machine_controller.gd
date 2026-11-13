class_name MachineController
extends Node
## Reads the keyboard and feeds every part its input according to the blueprint key bindings.

var machine: Machine
## When false the last input stays frozen (the pilot is dead, the levers stay where they were).
var enabled := true
## Replaceable in tests.
var key_source: Callable = func(key: Key) -> bool: return Input.is_physical_key_pressed(key)


func _physics_process(_delta: float) -> void:
	if not enabled or machine == null:
		return
	for part in machine.parts:
		if part.def.activation == PartDef.Activation.NONE:
			continue
		var value := 0.0
		if part.entry.key_positive != KEY_NONE and key_source.call(part.entry.key_positive):
			value += 1.0
		if part.entry.key_negative != KEY_NONE and key_source.call(part.entry.key_negative):
			value -= 1.0
		part.set_input(-value if part.entry.inverted else value)
