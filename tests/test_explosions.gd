extends TestCase

var _machine: Machine
var _explosions := 0
var _signals_for: Dictionary = {}  # cell -> count of EXPLODE signals


func _entry(id: StringName, cell: Vector3i) -> BlueprintEntry:
	var e := BlueprintEntry.new()
	e.part_id = id
	e.cell = cell
	return e


func _build(entries: Array) -> Machine:
	var bp := Blueprint.with_core()
	for e: BlueprintEntry in entries:
		bp.add(e)
	_machine = MachineAssembler.build(bp, tree.root.get_node("PartCatalog").defs,
			Transform3D(Basis.IDENTITY, Vector3(0, 2500, 0)))
	tree.root.add_child(_machine)
	_explosions = 0
	_signals_for = {}
	_machine.part_failed.connect(func(part: PartBody, mode: int, _t: float) -> void:
		if mode == FailureMode.EXPLODE:
			_explosions += 1
			_signals_for[part.entry.cell] = _signals_for.get(part.entry.cell, 0) + 1)
	return _machine


func _at(x: int) -> PartBody:
	for p in _machine.parts:
		if p.entry.cell == Vector3i(x, 0, 0):
			return p
	return null


func _frames(count: int) -> void:
	for _i in count:
		await tree.physics_frame


func test_explode_destroys_part_once() -> void:
	var m := _build([_entry(&"whistle", Vector3i(1, 0, 0))])
	await _frames(2)
	m.explode(_at(1))
	m.explode(_at(1))
	assert_eq(_explosions, 1)
	assert_eq(_at(1).state, PartBody.State.DESTROYED)
	assert_eq(m.joints_of(_at(1)).size(), 0)
	assert_true(not _at(1).visible)
	m.free()


func test_near_parts_detach_far_parts_stay() -> void:
	# Whistle radius 7 m: parts closer than 0.35 * 7 = 2.45 m are torn off.
	var m := _build([_entry(&"block", Vector3i(-1, 0, 0)), _entry(&"block", Vector3i(1, 0, 0)),
			_entry(&"block", Vector3i(2, 0, 0)), _entry(&"whistle", Vector3i(3, 0, 0))])
	await _frames(2)
	m.explode(_at(3))
	assert_eq(_at(2).state, PartBody.State.DETACHED, "1 m away")
	assert_eq(_at(1).state, PartBody.State.DETACHED, "2 m away")
	assert_eq(_at(0).state, PartBody.State.OK, "core, 3 m away")
	assert_eq(_at(-1).state, PartBody.State.OK, "4 m away")
	m.free()


func test_explosion_pushes_bodies_away() -> void:
	var m := _build([_entry(&"block", Vector3i(1, 0, 0)), _entry(&"whistle", Vector3i(2, 0, 0))])
	await _frames(2)
	m.explode(_at(2))
	await _frames(2)
	assert_true(_at(1).linear_velocity.x < -5.0, "block flies away from the blast: %s" % _at(1).linear_velocity)
	m.free()


func test_distant_explosion_wounds_but_does_not_kill() -> void:
	var m := _build([_entry(&"block", Vector3i(1, 0, 0)), _entry(&"block", Vector3i(2, 0, 0)),
			_entry(&"whistle", Vector3i(3, 0, 0))])
	await _frames(2)
	m.explode(_at(3))
	await _frames(3)
	var pilot: Pilot = m.pilot()
	# 2500 * (1 - 3/7) * 0.06 = 85.7 damage, and the blast push must not be counted as an impact.
	assert_almost(pilot.health, 14.3, 0.5)
	assert_true(pilot.is_alive())
	m.free()


func test_adjacent_barrel_kills_the_pilot() -> void:
	var m := _build([_entry(&"powder_barrel", Vector3i(1, 0, 0))])
	await _frames(2)
	m.explode(_at(1))
	assert_true(not m.pilot().is_alive())
	m.free()


func test_chain_detonation_each_barrel_once() -> void:
	var m := _build([_entry(&"powder_barrel", Vector3i(1, 0, 0)), _entry(&"powder_barrel", Vector3i(2, 0, 0)),
			_entry(&"powder_barrel", Vector3i(3, 0, 0))])
	await _frames(2)
	m.explode(_at(3))
	assert_eq(_explosions, 1, "the others wait for their fuse")
	await tree.create_timer(1.0).timeout
	for x in [1, 2, 3]:
		assert_eq(_at(x).state, PartBody.State.DESTROYED, "barrel %d" % x)
		assert_eq(_signals_for.get(Vector3i(x, 0, 0), 0), 1, "barrel %d signals" % x)
	assert_eq(_explosions, 3)
	m.free()


func test_parts_without_explosive_power_just_break() -> void:
	var m := _build([_entry(&"block", Vector3i(1, 0, 0)), _entry(&"block", Vector3i(2, 0, 0))])
	await _frames(2)
	m.explode(_at(2))
	assert_eq(_at(2).state, PartBody.State.DESTROYED)
	assert_eq(_at(1).state, PartBody.State.OK, "no blast, neighbours untouched")
	m.free()


func test_machine_freed_during_pending_detonation() -> void:
	var m := _build([_entry(&"powder_barrel", Vector3i(1, 0, 0)), _entry(&"powder_barrel", Vector3i(2, 0, 0))])
	await _frames(2)
	m.explode(_at(2))
	m.free()
	await tree.create_timer(0.5).timeout
	assert_true(not is_instance_valid(m))
	assert_eq(_explosions, 1, "the pending barrel never went off")


func test_dead_pilot_freezes_input_and_hud_says_so() -> void:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	load("res://tools/shots/cart.gd").build(session, 2)
	session.enter_sim(3)
	session.sim_mode.failures.set_physics_process(false)
	var keys := {KEY_UP: true}
	session.sim_mode.controller.key_source = func(key: Key) -> bool: return keys.has(key)
	await _frames(3)
	var wheel: PartBody
	for p in session.sim_mode.machine.parts:
		if p.entry.part_id == &"motor_wheel":
			wheel = p
	assert_eq(wheel.input_value, 1.0)
	session.sim_mode.machine.pilot().take_damage(1000.0)
	keys.clear()
	await _frames(3)
	assert_eq(wheel.input_value, 1.0, "levers stay where they were")
	assert_eq(session.sim_hud.status_text(), "Управление потеряно")
	assert_eq(session.mode, LevelSession.Mode.SIM, "death is not the end of the launch")
	session.free()


func test_return_to_build_during_chain_detonation() -> void:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[game.levels.size() - 1]
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	var catalog: Node = tree.root.get_node("PartCatalog")
	session.blueprint.clear()
	for x in [1, 2]:
		var e := _entry(&"powder_barrel", Vector3i(x, 0, 0))
		e.tier = 2
		session.blueprint.add(e)
	assert_true(catalog != null)
	session.enter_sim(4)
	if session.mode == LevelSession.Mode.SIM:
		var machine := session.sim_mode.machine
		await _frames(2)
		for p in machine.parts:
			if p.entry.cell == Vector3i(2, 0, 0):
				machine.explode(p)
		session.enter_build()
		await tree.create_timer(0.5).timeout
		assert_eq(session.sim_mode.machine, null)
	session.free()
