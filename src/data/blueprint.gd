class_name Blueprint
extends RefCounted
## A machine design: pure data, no nodes. The core always sits at cell (0,0,0).

const CORE_ID := &"core"

var entries: Array[BlueprintEntry] = []


static func with_core() -> Blueprint:
	var bp := Blueprint.new()
	bp.entries.append(_core_entry())
	return bp


static func _core_entry() -> BlueprintEntry:
	var core := BlueprintEntry.new()
	core.part_id = CORE_ID
	core.cell = Vector3i.ZERO
	return core


func get_at(cell: Vector3i) -> BlueprintEntry:
	for e in entries:
		if e.cell == cell:
			return e
	return null


func add(entry: BlueprintEntry) -> void:
	entries.append(entry)


func remove_at(cell: Vector3i) -> void:
	var e := get_at(cell)
	if e != null:
		entries.erase(e)


## A deep copy of the entries, for undo.
func snapshot() -> Array[BlueprintEntry]:
	var copies: Array[BlueprintEntry] = []
	for e in entries:
		copies.append(e.copy())
	return copies


## Replaces the entries with copies of a snapshot (the snapshot stays reusable).
func restore(saved: Array[BlueprintEntry]) -> void:
	entries.clear()
	for e in saved:
		entries.append(e.copy())


func clear() -> void:
	entries.clear()
	entries.append(_core_entry())
