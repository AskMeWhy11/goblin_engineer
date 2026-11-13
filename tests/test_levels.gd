extends TestCase

var _session: LevelSession


func _game() -> Node:
	return tree.root.get_node("Game")


func _catalog() -> Dictionary:
	return tree.root.get_node("PartCatalog").defs


func _frames(count: int) -> void:
	for _i in count:
		await tree.physics_frame


func _open(index: int) -> LevelSession:
	var game := _game()
	game.current_level = game.levels[index]
	game.blueprint_for(game.levels[index]).clear()
	_session = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(_session)
	return _session


## The cheapest way to pass the risk threshold: junk copies of the riskiest allowed part.
func _risky_blueprint(level: LevelDef, bp: Blueprint) -> void:
	var best: PartDef = null
	var best_value := 0.0
	for id in level.allowed_parts:
		var def: PartDef = _catalog().get(id)
		if def == null or def.base_face != Vector3i.ZERO:
			continue
		var tier := def.tiers[-1]
		var risk := tier.rates.z + tier.rates.y / 2.0 + tier.rates.x / 3.0
		if risk / maxf(1.0, def.price(def.tiers.size() - 1)) > best_value:
			best_value = risk / maxf(1.0, def.price(def.tiers.size() - 1))
			best = def
	var tier_risk := best.tiers[-1].rates.z + best.tiers[-1].rates.y / 2.0 + best.tiers[-1].rates.x / 3.0
	for i in ceili(level.risk_min / tier_risk):
		var e := BlueprintEntry.new()
		e.part_id = best.id
		e.cell = Vector3i(0, 1 + i, 0)
		e.tier = best.tiers.size() - 1
		bp.add(e)


func test_all_four_levels_load() -> void:
	var ids: Array = _game().levels.map(func(l: LevelDef) -> StringName: return l.id)
	assert_eq(ids, [&"level_01", &"level_02", &"level_03", &"level_04"])


func test_level_scenes_follow_contract() -> void:
	for level: LevelDef in _game().levels:
		var root: Node = level.scene.instantiate()
		assert_true(root.get_node_or_null("BuildOrigin") is Marker3D, "%s BuildOrigin" % level.id)
		assert_true(root.get_node_or_null("Objective") is Objective, "%s Objective" % level.id)
		root.free()


func test_level_parts_exist_in_catalog() -> void:
	for level: LevelDef in _game().levels:
		assert_true(level.allowed_parts.size() >= 5, str(level.id))
		for id in level.allowed_parts:
			assert_true(_catalog().has(id), "%s: %s" % [level.id, id])


func test_level_limits_are_reachable() -> void:
	for level: LevelDef in _game().levels:
		var bp := Blueprint.with_core()
		_risky_blueprint(level, bp)
		var report := RiskCalculator.evaluate(bp, _catalog())
		assert_eq(RiskCalculator.launch_blocker(report, level), "", str(level.id))


func test_every_level_starts_and_returns_to_build() -> void:
	for index in _game().levels.size():
		var s := _open(index)
		_risky_blueprint(s.level, s.blueprint)
		s.enter_sim(1)
		assert_eq(s.mode, LevelSession.Mode.SIM, str(s.level.id))
		await _frames(30)
		assert_true(not s.sim_mode.objective.is_completed, "%s not won at start" % s.level.id)
		s.enter_build()
		s.free()


func test_reaching_the_flag_wins_even_with_a_dead_pilot() -> void:
	var s := _open(0)
	_risky_blueprint(s.level, s.blueprint)
	s.enter_sim(1)
	s.sim_mode.failures.set_physics_process(false)
	var machine := s.sim_mode.machine
	await _frames(5)
	assert_true(not s.result_screen.visible)
	machine.pilot().take_damage(1000.0)
	var offset: Vector3 = s.sim_mode.objective.global_position - machine.core().global_position
	for p in machine.parts:
		p.global_position += Vector3(offset.x, 0, offset.z)
	await _frames(5)
	assert_true(s.sim_mode.objective.is_completed)
	assert_true(s.result_screen.visible)
	assert_true(s.result_screen.summary.contains("Испытатель не выжил"), s.result_screen.summary)
	assert_true(s.result_screen.summary.contains("Зерно: 1"), s.result_screen.summary)
	assert_eq(s.mode, LevelSession.Mode.SIM, "simulation keeps running under the result screen")
	s.enter_build()
	assert_true(not s.result_screen.visible)
	assert_true(not s.sim_mode.objective.is_completed, "objective reset")
	s.free()


func test_repeat_with_same_seed_restarts_the_launch() -> void:
	var s := _open(0)
	_risky_blueprint(s.level, s.blueprint)
	s.enter_sim(42)
	var first := s.sim_mode.machine
	await _frames(3)
	s.enter_sim(s.last_seed)
	assert_eq(s.last_seed, 42)
	assert_true(not is_instance_valid(first))
	assert_true(s.sim_mode.machine != null)
	s.free()


func test_cargo_level_wins_when_the_crate_is_in_the_zone() -> void:
	var s := _open(1)
	_risky_blueprint(s.level, s.blueprint)
	s.enter_sim(1)
	s.sim_mode.failures.set_physics_process(false)
	var cargo := s.level_root.get_node("Cargo") as RigidBody3D
	assert_true(cargo != null)
	var start := cargo.global_position
	await _frames(5)
	assert_true(not s.sim_mode.objective.is_completed)
	cargo.global_position = s.sim_mode.objective.global_position + Vector3(0, 1, 0)
	cargo.linear_velocity = Vector3.ZERO
	await _frames(5)
	assert_true(s.sim_mode.objective.is_completed)
	s.enter_build()
	await _frames(2)
	assert_true(cargo.global_position.distance_to(start) < 0.5, "crate is back")
	s.free()


func test_tower_level_wins_when_enough_pieces_are_down() -> void:
	var s := _open(2)
	_risky_blueprint(s.level, s.blueprint)
	s.enter_sim(1)
	s.sim_mode.failures.set_physics_process(false)
	var pieces := tree.get_nodes_in_group(&"destructible")
	assert_eq(pieces.size(), 12)
	await _frames(5)
	assert_true(not s.sim_mode.objective.is_completed)
	for i in 9:
		pieces[i].take_hit(10000.0)
	await _frames(5)
	assert_true(s.sim_mode.objective.is_completed, "9 of 12 down, 3 survivors allowed")
	s.enter_build()
	for piece in pieces:
		assert_true(not piece.is_destroyed)
	s.free()


func test_gap_level_has_a_gap() -> void:
	var s := _open(3)
	await _frames(3)
	var space := s.get_world_3d().direct_space_state
	var over_gap := PhysicsRayQueryParameters3D.create(Vector3(24, 5, 0), Vector3(24, -20, 0), Layers.WORLD)
	var over_ground := PhysicsRayQueryParameters3D.create(Vector3(40, 5, 0), Vector3(40, -20, 0), Layers.WORLD)
	assert_true(space.intersect_ray(over_gap).is_empty(), "nothing under the gap")
	assert_true(not space.intersect_ray(over_ground).is_empty(), "ground on the far side")
	s.free()
