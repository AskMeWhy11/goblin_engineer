extends TestCase

var _cat: Dictionary
var _level: LevelDef


func _init() -> void:
	_cat = {
		&"core": _part(&"core", [], false),
		&"block": _part(&"block", []),
		&"wheel": _part(&"wheel", [Vector3i.LEFT]),
		&"secret": _part(&"secret", []),
	}
	_level = LevelDef.new()
	_level.volume_min = Vector3i(-2, 0, -2)
	_level.volume_max = Vector3i(2, 3, 2)
	_level.allowed_parts = [&"block", &"wheel"]


func _part(id: StringName, faces: Array, removable := true) -> PartDef:
	var def := PartDef.new()
	def.id = id
	def.removable = removable
	def.attach_faces.assign(faces)
	return def


func _bp(cells: Array) -> Blueprint:
	var bp := Blueprint.with_core()
	for c: Vector3i in cells:
		var e := BlueprintEntry.new()
		e.part_id = &"block"
		e.cell = c
		bp.add(e)
	return bp


func _can_place(bp: Blueprint, id: StringName, cell: Vector3i, orientation := 0) -> bool:
	return BlueprintRules.can_place(bp, _cat, _cat[id], cell, orientation, _level)


func test_place_next_to_core_allowed() -> void:
	assert_true(_can_place(_bp([]), &"block", Vector3i(1, 0, 0)))


func test_place_in_occupied_cell_rejected() -> void:
	assert_true(not _can_place(_bp([]), &"block", Vector3i.ZERO))


func test_place_floating_rejected() -> void:
	assert_true(not _can_place(_bp([]), &"block", Vector3i(2, 0, 0)))


func test_place_outside_volume_rejected() -> void:
	var bp := _bp([Vector3i(1, 0, 0), Vector3i(2, 0, 0)])
	assert_true(not _can_place(bp, &"block", Vector3i(3, 0, 0)))


func test_place_not_allowed_part_rejected() -> void:
	assert_true(not _can_place(_bp([]), &"secret", Vector3i(1, 0, 0)))


func test_wheel_needs_mount_face_toward_neighbor() -> void:
	assert_true(_can_place(_bp([]), &"wheel", Vector3i(1, 0, 0), 0))
	var flipped := Orientations.rotated(Orientations.rotated(0, Vector3i.UP), Vector3i.UP)
	assert_true(not _can_place(_bp([]), &"wheel", Vector3i(1, 0, 0), flipped))


func test_neighbors_lists_only_connected_cells() -> void:
	var bp := _bp([Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(2, 2, 0)])
	var n := BlueprintRules.neighbors(bp, _cat, Vector3i.ZERO)
	assert_eq(n.size(), 2)
	assert_true(n.has(Vector3i(1, 0, 0)) and n.has(Vector3i(0, 1, 0)))


func test_core_not_removable() -> void:
	assert_true(not BlueprintRules.can_remove(_bp([Vector3i(1, 0, 0)]), _cat, Vector3i.ZERO))


func test_remove_leaf_allowed() -> void:
	var bp := _bp([Vector3i(1, 0, 0), Vector3i(2, 0, 0)])
	assert_true(BlueprintRules.can_remove(bp, _cat, Vector3i(2, 0, 0)))


func test_remove_bridge_rejected() -> void:
	var bp := _bp([Vector3i(1, 0, 0), Vector3i(2, 0, 0)])
	assert_true(not BlueprintRules.can_remove(bp, _cat, Vector3i(1, 0, 0)))


func test_remove_allowed_when_alternate_path_exists() -> void:
	var bp := _bp([Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0)])
	assert_true(BlueprintRules.can_remove(bp, _cat, Vector3i(1, 0, 0)))


func test_remove_empty_cell_rejected() -> void:
	assert_true(not BlueprintRules.can_remove(_bp([]), _cat, Vector3i(1, 0, 0)))
