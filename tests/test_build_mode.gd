extends TestCase

var _session: LevelSession


func _open() -> LevelSession:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	game.blueprint_for(game.levels[0]).clear()
	_session = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(_session)
	return _session


func _close() -> void:
	_session.free()


func _def(id: StringName) -> PartDef:
	return tree.root.get_node("PartCatalog").get_def(id)


func test_place_adds_entry_and_ghost() -> void:
	var s := _open()
	var changes := [0]
	s.build_mode.blueprint_changed.connect(func(): changes[0] += 1)
	s.build_mode.selected_part = _def(&"block")
	assert_true(s.build_mode.try_place(Vector3i(1, 0, 0)))
	assert_eq(s.blueprint.entries.size(), 2)
	assert_eq(s.build_mode.ghost_count(), 2)
	assert_eq(changes[0], 1)
	assert_true(not s.build_mode.try_place(Vector3i(1, 0, 0)), "occupied")
	assert_true(not s.build_mode.try_place(Vector3i(3, 3, 3)), "floating")
	assert_eq(s.blueprint.entries.size(), 2)
	_close()


func test_entry_gets_selected_tier_and_default_keys() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"motor_wheel")
	s.build_mode.selected_tier = 2
	assert_true(s.build_mode.try_place(Vector3i(1, 0, 0)))
	var e := s.blueprint.get_at(Vector3i(1, 0, 0))
	assert_eq(e.tier, 2)
	assert_eq(e.key_positive, KEY_UP)
	assert_eq(e.key_negative, KEY_DOWN)
	_close()


func test_single_mount_part_orients_toward_neighbor() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"motor_wheel")
	for cell: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1)]:
		assert_true(s.build_mode.try_place(cell), str(cell))
		var e := s.blueprint.get_at(cell)
		assert_eq(Orientations.world_normal(e.orientation, Vector3i.LEFT), -cell)
	_close()


func test_remove_rules() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"block")
	s.build_mode.try_place(Vector3i(1, 0, 0))
	s.build_mode.try_place(Vector3i(2, 0, 0))
	assert_true(not s.build_mode.try_remove(Vector3i.ZERO), "core")
	assert_true(not s.build_mode.try_remove(Vector3i(1, 0, 0)), "bridge")
	assert_true(s.build_mode.try_remove(Vector3i(2, 0, 0)), "leaf")
	assert_eq(s.blueprint.entries.size(), 2)
	assert_eq(s.build_mode.ghost_count(), 2)
	_close()


func test_clear_keeps_core_only() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"block")
	s.build_mode.try_place(Vector3i(1, 0, 0))
	s.build_mode.clear_all()
	assert_eq(s.blueprint.entries.size(), 1)
	assert_eq(s.build_mode.ghost_count(), 1)
	_close()


func test_launch_blocked_for_core_only_machine() -> void:
	var s := _open()
	assert_eq(s.launch_blocker(), "Риск ниже порога: 0.0 из 1.3 %/с")
	s.enter_sim()
	assert_eq(s.mode, LevelSession.Mode.BUILD)
	assert_true(s.build_hud.launch_button.disabled)
	assert_eq(s.build_hud.blocker_label.text, "Риск ниже порога: 0.0 из 1.3 %/с")
	_close()


func test_hud_follows_blueprint() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"motor_wheel")
	s.build_mode.selected_tier = 2
	s.build_mode.try_place(Vector3i(1, 0, 0))
	assert_true(not s.build_hud.launch_button.disabled, "one junk wheel is 1.8 %/s, above 1.3")
	assert_eq(s.build_hud.blocker_label.text, "")
	assert_eq(s.build_hud.budget_label.text, "Бюджет: 18 / 250")
	assert_eq(s.build_hud.risk_bar.caption, "Риск: 1.8 из 1.3 %/с")
	_close()


func test_over_budget_blocks_launch() -> void:
	var s := _open()
	s.build_mode.selected_part = _def(&"whistle")
	s.build_mode.selected_tier = 0
	for cell: Vector3i in [Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)]:
		s.build_mode.try_place(cell)
	assert_eq(s.launch_blocker(), "Бюджет превышен на 110")
	assert_true(s.build_hud.launch_button.disabled)
	_close()
