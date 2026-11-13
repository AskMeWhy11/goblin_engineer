extends TestCase


func _entry(id: StringName, cell: Vector3i) -> BlueprintEntry:
	var e := BlueprintEntry.new()
	e.part_id = id
	e.cell = cell
	return e


func test_with_core_has_single_core_at_origin() -> void:
	var bp := Blueprint.with_core()
	assert_eq(bp.entries.size(), 1)
	assert_eq(bp.get_at(Vector3i.ZERO).part_id, Blueprint.CORE_ID)


func test_add_get_remove() -> void:
	var bp := Blueprint.with_core()
	var e := _entry(&"block", Vector3i(1, 0, 0))
	bp.add(e)
	assert_eq(bp.get_at(Vector3i(1, 0, 0)), e)
	bp.remove_at(Vector3i(1, 0, 0))
	assert_eq(bp.get_at(Vector3i(1, 0, 0)), null)


func test_clear_keeps_core() -> void:
	var bp := Blueprint.with_core()
	bp.add(_entry(&"block", Vector3i(0, 1, 0)))
	bp.clear()
	assert_eq(bp.entries.size(), 1)
	assert_eq(bp.entries[0].part_id, Blueprint.CORE_ID)
