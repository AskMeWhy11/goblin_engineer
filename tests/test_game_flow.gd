extends TestCase


func _game() -> Node:
	return tree.root.get_node_or_null("Game")


func _spawn(path: String) -> Node:
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	var node := packed.instantiate()
	tree.root.add_child(node)
	return node


func _buttons(node: Node) -> Array[Node]:
	return node.find_children("*", "Button", true, false)


func test_autoloads_present() -> void:
	assert_true(_game() != null, "Game")
	assert_true(tree.root.get_node_or_null("PartCatalog") != null, "PartCatalog")


func test_levels_loaded_in_id_order() -> void:
	var game := _game()
	assert_true(game != null)
	if game == null:
		return
	assert_true(game.levels.size() >= 1)
	assert_eq(game.levels[0].id, &"level_01")
	for i in range(1, game.levels.size()):
		assert_true(String(game.levels[i - 1].id) < String(game.levels[i].id))


func test_blueprint_for_is_created_once_per_level() -> void:
	var game := _game()
	assert_true(game != null)
	if game == null:
		return
	var a: Blueprint = game.blueprint_for(game.levels[0])
	assert_eq(a.get_at(Vector3i.ZERO).part_id, Blueprint.CORE_ID)
	assert_eq(game.blueprint_for(game.levels[0]), a)


func test_input_actions_registered() -> void:
	for action in [&"toggle_sim", &"pause", &"repeat_seed", &"build_rotate_y", &"build_rotate_x", &"build_delete"]:
		assert_true(InputMap.has_action(action), action)


func test_main_menu_has_play_and_quit() -> void:
	var menu := _spawn("res://scenes/ui/main_menu.tscn")
	assert_true(menu != null)
	if menu == null:
		return
	await tree.process_frame
	var texts := _buttons(menu).map(func(b): return b.text)
	assert_true(texts.has("Играть") and texts.has("Выход"), str(texts))
	menu.free()


func test_level_select_has_a_card_per_level() -> void:
	var game := _game()
	var screen := _spawn("res://scenes/ui/level_select.tscn")
	assert_true(screen != null and game != null)
	if screen == null or game == null:
		return
	await tree.process_frame
	# one "play" button per level plus "back"
	assert_eq(_buttons(screen).size(), game.levels.size() + 1)
	screen.free()


func test_level_session_switches_modes() -> void:
	var game := _game()
	assert_true(game != null)
	if game == null:
		return
	game.current_level = game.levels[0]
	var session := _spawn("res://scenes/level_session.tscn")
	assert_true(session != null)
	if session == null:
		return
	await tree.process_frame
	var changes := [0]
	session.mode_changed.connect(func(_m): changes[0] += 1)
	assert_eq(session.mode, LevelSession.Mode.BUILD)
	assert_true(session.level_root.get_node_or_null("BuildOrigin") != null)
	assert_true(session.level_root.get_node_or_null("Objective") != null)
	session.enter_sim(123)
	assert_eq(session.mode, LevelSession.Mode.SIM)
	assert_eq(session.last_seed, 123)
	session.enter_build()
	assert_eq(session.mode, LevelSession.Mode.BUILD)
	assert_eq(changes[0], 2)
	session.free()
	await tree.process_frame
