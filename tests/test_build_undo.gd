extends TestCase

var _session: LevelSession


func _open() -> BuildMode:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	game.blueprint_for(game.levels[0]).clear()
	_session = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(_session)
	return _session.build_mode


func _close() -> void:
	_session.free()


func _def(id: StringName) -> PartDef:
	return tree.root.get_node("PartCatalog").get_def(id)


func _key(code: Key, ctrl := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.ctrl_pressed = ctrl
	event.pressed = true
	return event


func _cells() -> Array:
	var cells: Array = _session.blueprint.entries.map(func(e: BlueprintEntry) -> Vector3i: return e.cell)
	cells.sort()
	return cells


func test_blueprint_snapshot_is_a_deep_copy() -> void:
	var bp := Blueprint.with_core()
	var e := BlueprintEntry.new()
	e.part_id = &"block"
	e.cell = Vector3i(1, 0, 0)
	e.tier = 1
	e.key_positive = KEY_Q
	e.inverted = true
	bp.add(e)
	var snap := bp.snapshot()
	e.tier = 2
	bp.remove_at(Vector3i(1, 0, 0))
	bp.restore(snap)
	var back := bp.get_at(Vector3i(1, 0, 0))
	assert_true(back != null and back != e, "a fresh copy")
	if back != null:
		assert_eq(back.tier, 1)
		assert_eq(back.key_positive, KEY_Q)
		assert_eq(back.inverted, true)
		assert_eq(back.part_id, &"block")
	assert_eq(bp.entries.size(), 2)


func test_undo_with_no_history_does_nothing() -> void:
	var build := _open()
	assert_true(not build.undo())
	assert_eq(_session.blueprint.entries.size(), 1)
	_close()


func test_undo_takes_back_placements_one_at_a_time() -> void:
	var build := _open()
	var changes := [0]
	build.blueprint_changed.connect(func() -> void: changes[0] += 1)
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(2, 0, 0))
	assert_true(build.undo())
	assert_eq(_cells(), [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	assert_eq(build.ghost_count(), 2)
	assert_eq(changes[0], 3, "undo reports a change so the HUD updates")
	assert_true(build.undo())
	assert_eq(_cells(), [Vector3i(0, 0, 0)])
	assert_true(not build.undo(), "history is empty again")
	_close()


func test_failed_actions_leave_no_history() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(3, 3, 3))
	build.try_remove(Vector3i.ZERO)
	assert_true(build.undo())
	assert_eq(_session.blueprint.entries.size(), 1, "one undo removes the only real action")
	assert_true(not build.undo())
	_close()


func test_undo_restores_a_removed_part_exactly() -> void:
	var build := _open()
	build.selected_part = _def(&"motor_wheel")
	build.selected_tier = 2
	build.try_place(Vector3i(0, 0, 1))
	var before := _session.blueprint.get_at(Vector3i(0, 0, 1))
	var orientation := before.orientation
	build.try_remove(Vector3i(0, 0, 1))
	assert_eq(_session.blueprint.get_at(Vector3i(0, 0, 1)), null)
	assert_true(build.undo())
	var back := _session.blueprint.get_at(Vector3i(0, 0, 1))
	assert_true(back != null)
	if back != null:
		assert_eq(back.tier, 2)
		assert_eq(back.orientation, orientation)
		assert_eq(back.key_positive, KEY_UP)
	assert_true(build.ghost_at(Vector3i(0, 0, 1)) != null)
	_close()


func test_undo_restores_everything_after_clear() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(0, 1, 0))
	build.clear_all()
	assert_true(build.undo())
	assert_eq(_session.blueprint.entries.size(), 3)
	assert_eq(build.ghost_count(), 3)
	_close()


func test_undo_takes_back_an_edit_made_in_the_part_panel() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.select_cell(Vector3i(1, 0, 0))
	var panel := _session.build_hud.part_panel
	assert_eq(panel.entry, _session.blueprint.get_at(Vector3i(1, 0, 0)))
	panel.set_tier(2)
	assert_eq(_session.blueprint.get_at(Vector3i(1, 0, 0)).tier, 2)
	assert_true(build.undo())
	assert_eq(_session.blueprint.get_at(Vector3i(1, 0, 0)).tier, 0)
	assert_true((build.ghost_at(Vector3i(1, 0, 0)).get_node("Tier0") as Node3D).visible)
	assert_true(not panel.visible, "selection is dropped: the old entry object is gone")
	_close()


func test_delete_removes_the_selected_part() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	assert_true(not build.delete_selected(), "nothing selected")
	build.select_cell(Vector3i(1, 0, 0))
	assert_eq(build.selected_entry, _session.blueprint.get_at(Vector3i(1, 0, 0)))
	assert_true(build.delete_selected())
	assert_eq(_session.blueprint.entries.size(), 1)
	assert_eq(build.selected_entry, null)
	assert_true(build.undo(), "delete can be undone")
	assert_eq(_session.blueprint.entries.size(), 2)
	_close()


func test_delete_refuses_core_and_load_bearing_parts() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(2, 0, 0))
	build.select_cell(Vector3i.ZERO)
	assert_true(not build.delete_selected(), "core")
	build.select_cell(Vector3i(1, 0, 0))
	assert_true(not build.delete_selected(), "bridge")
	assert_eq(_session.blueprint.entries.size(), 3)
	assert_eq(build.selected_entry, _session.blueprint.get_at(Vector3i(1, 0, 0)), "still selected")
	_close()


func test_selecting_an_empty_cell_clears_the_selection() -> void:
	var build := _open()
	build.select_cell(Vector3i.ZERO)
	assert_true(build.selected_entry != null)
	build.select_cell(Vector3i(3, 3, 3))
	assert_eq(build.selected_entry, null)
	_close()


func test_keyboard_shortcuts() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	build.try_place(Vector3i(1, 0, 0))
	build.try_place(Vector3i(0, 1, 0))
	build._unhandled_input(_key(KEY_Z))
	assert_eq(_session.blueprint.entries.size(), 3, "plain Z does nothing")
	build._unhandled_input(_key(KEY_Z, true))
	assert_eq(_session.blueprint.entries.size(), 2, "Ctrl+Z undoes")
	build.select_cell(Vector3i(1, 0, 0))
	build._unhandled_input(_key(KEY_DELETE))
	assert_eq(_session.blueprint.entries.size(), 1, "Del removes the selection")
	_close()


func test_history_is_bounded() -> void:
	var build := _open()
	build.selected_part = _def(&"block")
	for i in BuildMode.UNDO_LIMIT + 20:
		build.try_place(Vector3i(1, 0, 0))
		build.try_remove(Vector3i(1, 0, 0))
	var undone := 0
	while build.undo():
		undone += 1
	assert_eq(undone, BuildMode.UNDO_LIMIT)
	_close()


func test_hint_mentions_the_new_keys() -> void:
	_open()
	var texts: Array = _session.build_hud.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	assert_true(texts.any(func(t: String) -> bool: return t.contains("Ctrl+Z") and t.contains("Del")), "help text")
	_close()
