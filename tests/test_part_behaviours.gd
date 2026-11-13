extends TestCase

var _session: LevelSession
var _keys: Dictionary = {}


func _open_with_cart() -> Machine:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	_session = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(_session)
	load("res://tools/shots/cart.gd").build(_session, 1)
	# Keep the wheels reliable for the drive test; a junk whistle on top supplies the risk.
	_session.build_mode.selected_part = _def(&"whistle")
	_session.build_mode.selected_tier = 2
	_session.build_mode.try_place(Vector3i(0, 1, 0))
	_session.enter_sim(1)
	_session.sim_mode.controller.key_source = func(key: Key) -> bool: return _keys.has(key)
	return _session.sim_mode.machine


func _def(id: StringName) -> PartDef:
	return tree.root.get_node("PartCatalog").get_def(id)


func _frames(count: int) -> void:
	for _i in count:
		await tree.physics_frame


func _free_machine(entries: Array) -> Machine:
	var bp := Blueprint.with_core()
	for e: BlueprintEntry in entries:
		bp.add(e)
	var machine := MachineAssembler.build(bp, tree.root.get_node("PartCatalog").defs,
			Transform3D(Basis.IDENTITY, Vector3(0, 800, 0)))
	tree.root.add_child(machine)
	return machine


func _entry(id: StringName, cell: Vector3i, orientation := 0) -> BlueprintEntry:
	var e := BlueprintEntry.new()
	e.part_id = id
	e.cell = cell
	e.orientation = orientation
	var def := _def(id)
	e.key_positive = def.default_key_positive
	e.key_negative = def.default_key_negative
	return e


func _controller(machine: Machine) -> MachineController:
	var c := MachineController.new()
	c.machine = machine
	c.key_source = func(key: Key) -> bool: return _keys.has(key)
	machine.add_child(c)
	return c


func _part(machine: Machine, id: StringName) -> PartBody:
	for p in machine.parts:
		if p.entry.part_id == id:
			return p
	return null


func test_controller_maps_keys_to_input() -> void:
	var wheel_entry := _entry(&"motor_wheel", Vector3i(1, 0, 0))
	var m := _free_machine([wheel_entry])
	_controller(m)
	var wheel := _part(m, &"motor_wheel")
	_keys = {KEY_UP: true}
	await _frames(2)
	assert_eq(wheel.input_value, 1.0)
	_keys = {KEY_DOWN: true}
	await _frames(2)
	assert_eq(wheel.input_value, -1.0)
	wheel_entry.inverted = true
	await _frames(2)
	assert_eq(wheel.input_value, 1.0)
	_keys = {}
	await _frames(2)
	assert_eq(wheel.input_value, 0.0)
	m.free()


func test_disabled_controller_keeps_last_input() -> void:
	var m := _free_machine([_entry(&"motor_wheel", Vector3i(1, 0, 0))])
	var c := _controller(m)
	_keys = {KEY_UP: true}
	await _frames(2)
	c.enabled = false
	_keys = {}
	await _frames(2)
	assert_eq(_part(m, &"motor_wheel").input_value, 1.0)
	m.free()


func test_wheel_is_joined_by_a_hinge() -> void:
	var m := _free_machine([_entry(&"motor_wheel", Vector3i(1, 0, 0))])
	var joints := m.joints_of(_part(m, &"motor_wheel"))
	assert_eq(joints.size(), 1)
	assert_true(joints[0] is HingeJoint3D)
	m.free()


func test_cart_drives_forward_and_back() -> void:
	var m := await _open_with_cart()
	await _frames(60)
	var x0 := m.core().global_position.x
	_keys = {KEY_UP: true}
	await _frames(180)
	var x1 := m.core().global_position.x
	assert_true(x1 > x0 + 2.0, "forward: %.2f -> %.2f" % [x0, x1])
	_keys = {KEY_DOWN: true}
	await _frames(300)
	var x2 := m.core().global_position.x
	assert_true(x2 < x1 - 1.0, "back: %.2f -> %.2f" % [x1, x2])
	_keys = {}
	_session.free()


func test_motor_wheel_load_follows_input() -> void:
	var m := _free_machine([_entry(&"motor_wheel", Vector3i(1, 0, 0))])
	var wheel := _part(m, &"motor_wheel")
	assert_eq(wheel.get_load(), 0.0)
	wheel.set_input(-1.0)
	assert_eq(wheel.get_load(), 1.0)
	m.free()


func test_motor_wheel_malfunction_stalls_or_sticks() -> void:
	var stalled := 0
	var stuck := 0
	for seed in 20:
		var m := _free_machine([_entry(&"motor_wheel", Vector3i(1, 0, 0))])
		m.rng.seed = seed
		var wheel := _part(m, &"motor_wheel")
		wheel.apply_malfunction()
		wheel.set_input(0.0)
		# A stuck wheel keeps working with no input; a stalled one never works.
		if wheel.get_load() > 0.0:
			stuck += 1
		else:
			wheel.set_input(1.0)
			assert_eq(wheel.get_load(), 0.0, "stalled wheel ignores input")
			stalled += 1
		m.free()
	assert_true(stalled > 0 and stuck > 0, "stalled=%d stuck=%d" % [stalled, stuck])


func test_steering_hinge_turns_both_ways_and_returns() -> void:
	# Hinge mounted on the core's +X side, a block hanging on the hinge.
	var m := _free_machine([_entry(&"steering_hinge", Vector3i(1, 0, 0)), _entry(&"block", Vector3i(2, 0, 0))])
	_controller(m)
	var hinge := _part(m, &"steering_hinge")
	_keys = {KEY_RIGHT: true}
	await _frames(90)
	var right: float = hinge.current_angle()
	_keys = {KEY_LEFT: true}
	await _frames(120)
	var left: float = hinge.current_angle()
	_keys = {}
	await _frames(120)
	var center: float = hinge.current_angle()
	assert_almost(absf(right), deg_to_rad(35.0), deg_to_rad(6.0), "right")
	assert_almost(left, -right, deg_to_rad(8.0), "left mirrors right")
	assert_almost(center, 0.0, deg_to_rad(6.0), "returns to centre")
	m.free()


func test_rocket_pushes_along_its_axis() -> void:
	# Two rockets mirrored around the core so the thrust does not spin the machine.
	var flipped := Orientations.rotated(Orientations.rotated(0, Vector3i.BACK), Vector3i.BACK)
	var m := _free_machine([_entry(&"rocket", Vector3i(1, 0, 0)), _entry(&"rocket", Vector3i(-1, 0, 0), flipped)])
	_controller(m)
	var rocket := _part(m, &"rocket")
	var axis := rocket.world_axis(Vector3.BACK)
	await _frames(30)
	var before := m.core().linear_velocity.dot(axis)
	assert_eq(rocket.get_load(), 0.0)
	_keys = {KEY_SHIFT: true}
	await _frames(60)
	assert_eq(rocket.get_load(), 1.0)
	assert_true(m.core().linear_velocity.dot(axis) > before + 5.0)
	rocket.apply_malfunction()
	await _frames(2)
	assert_eq(rocket.get_load(), 0.0, "dead rocket")
	_keys = {}
	m.free()


func test_cannon_fires_once_per_press_with_cooldown() -> void:
	var m := _free_machine([_entry(&"cannon", Vector3i(1, 0, 0))])
	_controller(m)
	var shots := func() -> int: return tree.get_nodes_in_group(&"projectile").size()
	_keys = {KEY_C: true}
	await _frames(10)
	assert_eq(shots.call(), 1, "held key fires once")
	_keys = {}
	await _frames(3)
	_keys = {KEY_C: true}
	await _frames(3)
	assert_eq(shots.call(), 1, "still reloading")
	assert_eq(_part(m, &"cannon").get_load(), 1.0, "loaded while reloading")
	_keys = {}
	await _frames(130)
	_keys = {KEY_C: true}
	await _frames(3)
	assert_eq(shots.call(), 2, "fires again after 2 s")
	_keys = {}
	m.free()
	await _frames(1)
	assert_eq(shots.call(), 0, "projectiles die with the machine")


func test_block_malfunction_loosens_joints_without_removing_them() -> void:
	var m := _free_machine([_entry(&"block", Vector3i(1, 0, 0)), _entry(&"block", Vector3i(2, 0, 0))])
	var block: PartBody
	for p in m.parts:
		if p.entry.cell == Vector3i(1, 0, 0):
			block = p
	block.apply_malfunction()
	var joints := m.joints_of(block)
	assert_eq(joints.size(), 2)
	for j in joints:
		var g := j as Generic6DOFJoint3D
		assert_true(g != null and g.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT) > 0.2)
	m.free()
