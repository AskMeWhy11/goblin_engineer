extends TestCase

const IDS: Array[StringName] = [&"core", &"block", &"ballast", &"free_wheel", &"motor_wheel",
		&"steering_hinge", &"rocket", &"cannon", &"powder_barrel", &"whistle"]

var _defs: Dictionary


func _init() -> void:
	var script: GDScript = load("res://src/core/part_catalog.gd")
	if script != null:
		_defs = script.load_all()


func test_catalog_has_exactly_the_ten_parts() -> void:
	assert_eq(_defs.size(), 10)
	for id in IDS:
		assert_true(_defs.has(id), str(id))


func test_core_has_one_tier_and_is_not_removable() -> void:
	var core: PartDef = _defs.get(&"core")
	assert_true(core != null)
	if core == null:
		return
	assert_eq(core.tiers.size(), 1)
	assert_eq(core.removable, false)
	assert_eq(core.tiers[0].rates, Vector3.ZERO)


func test_other_parts_have_three_tiers_and_a_scene() -> void:
	assert_true(not _defs.is_empty())
	for id: StringName in _defs:
		var def: PartDef = _defs[id]
		assert_true(def.scene != null, "%s scene" % id)
		if id != &"core":
			assert_eq(def.tiers.size(), 3, str(id))
			assert_eq(def.removable, true, str(id))


func test_prices_and_rates_follow_the_table() -> void:
	var block: PartDef = _defs.get(&"block")
	var whistle: PartDef = _defs.get(&"whistle")
	assert_true(block != null and whistle != null)
	if block == null or whistle == null:
		return
	assert_eq(block.price(2), 3)
	assert_eq(block.price(0), 10)
	assert_almost(whistle.tiers[0].rates.z, 0.0016, 1e-6)
	assert_almost(whistle.tiers[2].rates.z, 0.04, 1e-6)
	assert_almost(block.tiers[2].strength_margin, 0.8, 1e-6)


func test_only_mechanisms_explode() -> void:
	assert_true(not _defs.is_empty())
	for id: StringName in _defs:
		var def: PartDef = _defs[id]
		if id in [&"core", &"block", &"ballast"]:
			assert_eq(def.explosion_power, 0.0, str(id))
			assert_eq(def.tiers[-1].rates.z, 0.0, str(id))
		else:
			assert_true(def.explosion_power > 0.0 and def.explosion_radius > 0.0, str(id))
			assert_true(def.tiers[-1].rates.z > 0.0, str(id))


func test_mount_faces() -> void:
	assert_true(not _defs.is_empty())
	for id: StringName in [&"free_wheel", &"motor_wheel", &"rocket", &"cannon"]:
		var def: PartDef = _defs.get(id)
		assert_true(def != null and def.attach_faces == [Vector3i.LEFT], str(id))
	var block: PartDef = _defs.get(&"block")
	assert_true(block != null and block.attach_faces.is_empty())
