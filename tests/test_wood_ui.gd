extends TestCase


func _holder() -> Control:
	var c := Control.new()
	tree.root.add_child(c)
	return c


func test_plank_layout_is_stable_for_a_seed() -> void:
	var a := WoodBackdrop.layout(Vector2(300, 400), 7)
	var b := WoodBackdrop.layout(Vector2(300, 400), 7)
	var c := WoodBackdrop.layout(Vector2(300, 400), 8)
	assert_eq(a, b)
	assert_true(a != c, "another seed gives other planks")


func test_planks_cover_the_panel_and_stay_near_it() -> void:
	var size := Vector2(300, 400)
	var planks := WoodBackdrop.layout(size, 3)
	assert_true(planks.size() >= 3, "several planks, got %d" % planks.size())
	var allowed := Rect2(Vector2.ZERO, size).grow(24.0)
	var left := INF
	var right := -INF
	for plank: PackedVector2Array in planks:
		assert_true(plank.size() >= 4)
		for point in plank:
			assert_true(allowed.has_point(point), "point %s" % point)
			left = minf(left, point.x)
			right = maxf(right, point.x)
	assert_true(left <= 4.0 and right >= size.x - 4.0, "spans the width: %s..%s" % [left, right])


func test_tiny_panel_still_gets_planks() -> void:
	assert_true(WoodBackdrop.layout(Vector2(40, 20), 1).size() >= 1)
	assert_eq(WoodBackdrop.layout(Vector2.ZERO, 1).size(), 0)


func test_panel_has_a_wood_backdrop_behind_its_content() -> void:
	var holder := _holder()
	var box := UiKit.panel(holder)
	var panel := holder.get_child(0)
	assert_true(panel.get_child(0) is WoodBackdrop, "backdrop is drawn first")
	assert_true(panel.is_ancestor_of(box))
	holder.free()


func test_buttons_are_crooked_planks_and_turn_red_when_pressed() -> void:
	var holder := _holder()
	var b := UiKit.button(holder, "Запуск", func() -> void: pass)
	var normal := b.get_theme_stylebox("normal") as StyleBoxFlat
	var pressed := b.get_theme_stylebox("pressed") as StyleBoxFlat
	assert_true(normal != null and pressed != null)
	if normal != null and pressed != null:
		assert_true(absf(normal.skew.x) > 0.01, "crooked")
		assert_true(normal.border_width_left >= 2)
		assert_true(pressed.bg_color.r > pressed.bg_color.g * 1.5, "pressed plank is red: %s" % pressed.bg_color)
	holder.free()


func test_same_text_gives_the_same_plank() -> void:
	var holder := _holder()
	var a := UiKit.button(holder, "Блок", func() -> void: pass)
	var b := UiKit.button(holder, "Блок", func() -> void: pass)
	assert_eq((a.get_theme_stylebox("normal") as StyleBoxFlat).skew, (b.get_theme_stylebox("normal") as StyleBoxFlat).skew)
	holder.free()


func test_tag_is_sized_to_its_text_and_tilted() -> void:
	var holder := _holder()
	var short_tag := UiKit.tag(holder, "Да")
	var long_tag := UiKit.tag(holder, "Журнал отказов")
	assert_eq(long_tag.text, "Журнал отказов")
	assert_true(long_tag.get_minimum_size().x > short_tag.get_minimum_size().x + 40.0)
	assert_true(long_tag.get_minimum_size().y >= 24.0)
	assert_true(absf(long_tag.tilt_degrees) > 0.5 and absf(long_tag.tilt_degrees) <= 5.0)
	holder.free()


func test_screens_use_the_wood_kit() -> void:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	await tree.process_frame
	assert_true(session.build_hud.find_children("*", "WoodBackdrop", true, false).size() >= 3, "build HUD panels")
	assert_true(session.build_hud.find_children("*", "WoodTag", true, false).size() >= 2, "build HUD tags")
	assert_true(session.sim_hud.find_children("*", "WoodBackdrop", true, false).size() >= 2, "sim HUD panels")
	session.free()
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	assert_true(menu.find_children("*", "WoodBackdrop", true, false).size() >= 1, "menu wall")
	menu.free()
