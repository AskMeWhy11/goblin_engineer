extends TestCase

var _machine: Machine


func _build(cells: Array, origin := Vector3.ZERO) -> Machine:
	var bp := Blueprint.with_core()
	for c: Vector3i in cells:
		var e := BlueprintEntry.new()
		e.part_id = &"block"
		e.cell = c
		e.tier = 1
		bp.add(e)
	var catalog: Dictionary = tree.root.get_node("PartCatalog").defs
	# Far away from anything other tests may have left in the world.
	_machine = MachineAssembler.build(bp, catalog, Transform3D(Basis.IDENTITY, origin + Vector3(0, 500, 0)))
	tree.root.add_child(_machine)
	return _machine


func _part(cell: Vector3i) -> PartBody:
	for p in _machine.parts:
		if p.entry.cell == cell:
			return p
	return null


func test_one_body_per_entry() -> void:
	var m := _build([Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)])
	assert_eq(m.parts.size(), 4)
	assert_eq(m.core().entry.part_id, Blueprint.CORE_ID)
	m.free()


func test_joint_per_connected_pair() -> void:
	var row := _build([Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)])
	assert_eq(row.joint_count(), 3)
	row.free()
	var square := _build([Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0)])
	assert_eq(square.joint_count(), 4)
	square.free()


func test_positions_follow_cells() -> void:
	var m := _build([Vector3i(1, 0, 0), Vector3i(2, 0, 0)], Vector3(10, 0, 0))
	assert_true(_part(Vector3i(2, 0, 0)).global_position.is_equal_approx(Vector3(12, 500, 0)))
	m.free()


func test_parts_carry_def_tier_and_mass() -> void:
	var m := _build([Vector3i(1, 0, 0)])
	var block := _part(Vector3i(1, 0, 0))
	assert_eq(block.def.id, &"block")
	assert_eq(block.tier, block.def.tiers[1])
	assert_almost(block.mass, 5.0, 0.001)
	assert_eq(block.machine, m)
	assert_eq(block.state, PartBody.State.OK)
	m.free()


func test_detach_removes_only_own_joints() -> void:
	var row := _build([Vector3i(1, 0, 0), Vector3i(2, 0, 0)])
	var a := _part(Vector3i(1, 0, 0))
	row.detach(a)
	assert_eq(row.joints_of(a).size(), 0)
	assert_eq(row.joints_of(_part(Vector3i(2, 0, 0))).size(), 0)
	assert_eq(a.state, PartBody.State.DETACHED)
	row.free()
	var square := _build([Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0)])
	square.detach(_part(Vector3i(1, 1, 0)))
	assert_eq(square.joint_count(), 2)
	square.free()


func test_detach_twice_is_safe() -> void:
	var m := _build([Vector3i(1, 0, 0)])
	var a := _part(Vector3i(1, 0, 0))
	m.detach(a)
	m.detach(a)
	assert_eq(a.state, PartBody.State.DETACHED)
	assert_eq(m.joint_count(), 0)
	m.free()


func test_attached_parts_excludes_detached() -> void:
	var m := _build([Vector3i(1, 0, 0), Vector3i(0, 1, 0)])
	m.detach(_part(Vector3i(1, 0, 0)))
	assert_eq(m.attached_parts().size(), 2)
	m.free()


func test_parts_cut_off_from_core_become_debris() -> void:
	var m := _build([Vector3i(1, 0, 0), Vector3i(2, 0, 0)])
	assert_eq(_part(Vector3i(2, 0, 0)).collision_layer, Layers.MACHINE)
	m.detach(_part(Vector3i(1, 0, 0)))
	assert_eq(_part(Vector3i(1, 0, 0)).collision_layer, Layers.DEBRIS)
	assert_eq(_part(Vector3i(2, 0, 0)).collision_layer, Layers.DEBRIS)
	assert_eq(m.core().collision_layer, Layers.MACHINE)
	# Cut off, but not broken: it can still fail later.
	assert_eq(_part(Vector3i(2, 0, 0)).state, PartBody.State.OK)
	m.free()


func test_session_builds_and_frees_the_machine() -> void:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	load("res://tools/shots/cart.gd").build(session, 2)
	session.enter_sim(5)
	assert_eq(session.mode, LevelSession.Mode.SIM)
	var machine: Machine = session.sim_mode.machine
	assert_true(machine != null)
	if machine != null:
		assert_eq(machine.parts.size(), 9)
		for _i in 120:
			await tree.physics_frame
		var y := machine.core().global_position.y
		assert_true(y > 0.3 and y < 1.5, "core rests on the ground, y=%s" % y)
	session.enter_build()
	assert_eq(session.sim_mode.machine, null)
	assert_true(not is_instance_valid(machine))
	session.free()
