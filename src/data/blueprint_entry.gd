class_name BlueprintEntry
extends RefCounted
## One placed part in a Blueprint. Pure data.

var part_id: StringName
var cell: Vector3i
var orientation: int
var tier: int
var key_positive: Key = KEY_NONE
var key_negative: Key = KEY_NONE
var inverted: bool


func copy() -> BlueprintEntry:
	var e := BlueprintEntry.new()
	e.part_id = part_id
	e.cell = cell
	e.orientation = orientation
	e.tier = tier
	e.key_positive = key_positive
	e.key_negative = key_negative
	e.inverted = inverted
	return e
