extends TestCase


func _frames(count: int) -> void:
	for _i in count:
		await tree.physics_frame


func _open_tower_level_with_whistles() -> LevelSession:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[2]
	var bp: Blueprint = game.blueprint_for(game.levels[2])
	bp.clear()
	for y in [1, 2]:
		var e := BlueprintEntry.new()
		e.part_id = &"whistle"
		e.cell = Vector3i(0, y, 0)
		e.tier = 2
		bp.add(e)
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	session.enter_sim(1)
	session.sim_mode.failures.set_physics_process(false)
	return session


func _whistle(machine: Machine, y: int) -> PartBody:
	for p in machine.parts:
		if p.entry.cell == Vector3i(0, y, 0):
			return p
	return null


func test_every_sound_has_audio_data() -> void:
	for kind: StringName in Sfx.KINDS:
		var stream := Sfx.make_stream(kind)
		assert_true(stream != null and stream.data.size() > 1000, kind)
		assert_eq(stream.mix_rate, Sfx.MIX_RATE, kind)


func test_unknown_sound_is_silent_not_a_crash() -> void:
	assert_eq(Sfx.make_stream(&"no_such_sound"), null)


func test_explosion_spawns_flash_and_sound_that_die_with_the_machine() -> void:
	var s := _open_tower_level_with_whistles()
	assert_eq(s.mode, LevelSession.Mode.SIM)
	await _frames(2)
	var machine := s.sim_mode.machine
	machine.explode(_whistle(machine, 2))
	assert_true(tree.get_nodes_in_group(&"fx").size() >= 1, "flash")
	assert_true(tree.get_nodes_in_group(&"sfx").size() >= 1, "sound")
	s.enter_build()
	await _frames(2)
	assert_eq(tree.get_nodes_in_group(&"fx").size(), 0)
	s.free()


func test_malfunction_makes_the_part_smoke() -> void:
	var s := _open_tower_level_with_whistles()
	await _frames(2)
	var machine := s.sim_mode.machine
	var whistle := _whistle(machine, 1)
	assert_true(whistle.get_node_or_null("Smoke") == null)
	machine.apply_failure(whistle, FailureMode.MALFUNCTION)
	assert_true(whistle.get_node_or_null("Smoke") != null)
	s.free()


func test_rocket_flame_shows_only_while_firing() -> void:
	var bp := Blueprint.with_core()
	var e := BlueprintEntry.new()
	e.part_id = &"rocket"
	e.cell = Vector3i(1, 0, 0)
	bp.add(e)
	var machine := MachineAssembler.build(bp, tree.root.get_node("PartCatalog").defs,
			Transform3D(Basis.IDENTITY, Vector3(0, 4000, 0)))
	tree.root.add_child(machine)
	var rocket: PartBody = machine.parts[1]
	await _frames(2)
	var flame := rocket.get_node_or_null("Flame") as Node3D
	assert_true(flame != null)
	if flame != null:
		assert_true(not flame.visible)
		rocket.set_input(1.0)
		await _frames(2)
		assert_true(flame.visible)
		rocket.apply_malfunction()
		await _frames(2)
		assert_true(not flame.visible, "a dead rocket has no flame")
	machine.free()
