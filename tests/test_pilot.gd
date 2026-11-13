extends TestCase


func _frames(count: int) -> void:
	for _i in count:
		await tree.physics_frame


func _core_only_machine() -> Machine:
	var machine := MachineAssembler.build(Blueprint.with_core(), tree.root.get_node("PartCatalog").defs,
			Transform3D(Basis.IDENTITY, Vector3(0, 1500, 0)))
	tree.root.add_child(machine)
	return machine


func test_explosion_damage_falloff() -> void:
	assert_almost(Pilot.explosion_damage(2500, 7, 1), 128.57, 0.01)
	assert_almost(Pilot.explosion_damage(200, 2, 1), 6.0, 0.01)
	assert_eq(Pilot.explosion_damage(2500, 7, 7), 0.0)
	assert_eq(Pilot.explosion_damage(2500, 7, 50), 0.0)


func test_impact_damage_threshold() -> void:
	assert_eq(Pilot.impact_damage(3.9), 0.0)
	assert_almost(Pilot.impact_damage(9.0), 50.0, 0.001)


func test_health_clamps_and_dies_once() -> void:
	var p := Pilot.new()
	var deaths := [0]
	var changes := [0]
	p.died.connect(func() -> void: deaths[0] += 1)
	p.health_changed.connect(func(_v: float) -> void: changes[0] += 1)
	p.take_damage(70)
	assert_true(p.is_alive())
	p.take_damage(70)
	p.take_damage(70)
	assert_eq(p.health, 0.0)
	assert_eq(deaths[0], 1)
	assert_eq(changes[0], 2, "no change events after death")
	assert_true(not p.is_alive())
	p.free()


func test_zero_or_negative_damage_is_ignored() -> void:
	var p := Pilot.new()
	p.take_damage(0.0)
	p.take_damage(-5.0)
	assert_eq(p.health, 100.0)
	p.free()


func test_hard_hit_on_the_cabin_hurts_the_pilot() -> void:
	var m := _core_only_machine()
	var core := m.core()
	await _frames(int(SimTuning.SHAKE_GRACE * 60.0) + 10)
	assert_eq(m.pilot().health, 100.0, "free fall alone does not hurt")
	core.linear_velocity += Vector3(9, 0, 0)
	await _frames(3)
	assert_true(m.pilot().health > 40.0 and m.pilot().health < 56.0, "health=%s" % m.pilot().health)
	m.free()


func test_hit_during_launch_grace_is_ignored() -> void:
	var m := _core_only_machine()
	await _frames(3)
	m.core().linear_velocity += Vector3(20, 0, 0)
	await _frames(3)
	assert_eq(m.pilot().health, 100.0)
	m.free()


func test_falling_out_of_the_world_kills() -> void:
	var m := _core_only_machine()
	await _frames(3)
	m.core().global_position = Vector3(0, SimTuning.KILL_Y - 5.0, 0)
	await _frames(3)
	assert_true(not m.pilot().is_alive())
	m.free()
