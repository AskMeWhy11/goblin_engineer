extends TestCase


func _defs() -> Dictionary:
	return tree.root.get_node("PartCatalog").defs


func _visible_tiers(root: Node) -> Array[String]:
	var result: Array[String] = []
	for name in ["Tier0", "Tier1", "Tier2"]:
		var node := root.get_node_or_null(name) as Node3D
		if node != null and node.visible:
			result.append(name)
	return result


func test_every_part_scene_has_body_shape_and_tier_nodes() -> void:
	assert_eq(_defs().size(), 10)
	for id: StringName in _defs():
		var def: PartDef = _defs()[id]
		var root: Node = def.scene.instantiate()
		var body := root.get_node_or_null("Mesh") as MeshInstance3D
		assert_true(body != null and body.mesh != null and body.mesh.get_surface_count() >= 1, "%s body" % id)
		assert_true(root.get_node_or_null("Shape") is CollisionShape3D, "%s shape" % id)
		for i in def.tiers.size():
			assert_true(root.get_node_or_null("Tier%d" % i) is MeshInstance3D, "%s Tier%d" % [id, i])
		root.free()


func test_bodies_have_a_toon_outline() -> void:
	for id: StringName in _defs():
		var root: Node = _defs()[id].scene.instantiate()
		var body := root.get_node("Mesh") as MeshInstance3D
		var material := body.mesh.surface_get_material(0) as StandardMaterial3D
		assert_true(material != null, "%s material" % id)
		if material != null:
			assert_eq(material.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, str(id))
			var outline := material.next_pass as StandardMaterial3D
			assert_true(outline != null and outline.cull_mode == BaseMaterial3D.CULL_FRONT and outline.grow, "%s outline" % id)
		root.free()


func test_parts_have_more_than_a_bare_primitive() -> void:
	for id: StringName in _defs():
		var root: Node = _defs()[id].scene.instantiate()
		var body := root.get_node("Mesh") as MeshInstance3D
		# Several colours means details (bands, rivets, pipes) were merged into the body.
		assert_true(body.mesh.get_surface_count() >= 2, "%s has %d surfaces" % [id, body.mesh.get_surface_count()])
		root.free()


func test_apply_tier_shows_exactly_one_wear_kit() -> void:
	var root: Node = _defs()[&"block"].scene.instantiate()
	assert_eq(_visible_tiers(root), ["Tier0"] as Array[String], "scene default")
	PartVisuals.apply_tier(root, 2)
	assert_eq(_visible_tiers(root), ["Tier2"] as Array[String])
	PartVisuals.apply_tier(root, 1)
	assert_eq(_visible_tiers(root), ["Tier1"] as Array[String])
	PartVisuals.apply_tier(root, 99)
	assert_eq(_visible_tiers(root), ["Tier2"] as Array[String], "clamped")
	root.free()


func test_junk_tier_carries_more_wear_than_good_tier() -> void:
	for id: StringName in [&"block", &"motor_wheel", &"rocket", &"powder_barrel", &"whistle"]:
		var root: Node = _defs()[id].scene.instantiate()
		var good := (root.get_node("Tier0") as MeshInstance3D).mesh
		var junk := (root.get_node("Tier2") as MeshInstance3D).mesh
		var good_faces := good.get_faces().size() if good != null else 0
		assert_true(junk != null and junk.get_faces().size() > good_faces, str(id))
		root.free()


func test_assembled_part_and_build_ghost_show_their_tier() -> void:
	var game := tree.root.get_node("Game")
	game.current_level = game.levels[0]
	game.blueprint_for(game.levels[0]).clear()
	var session: LevelSession = load("res://scenes/level_session.tscn").instantiate()
	tree.root.add_child(session)
	session.build_mode.selected_part = _defs()[&"block"]
	session.build_mode.selected_tier = 2
	session.build_mode.try_place(Vector3i(1, 0, 0))
	var ghost: Node = session.build_mode.ghost_at(Vector3i(1, 0, 0))
	assert_eq(_visible_tiers(ghost), ["Tier2"] as Array[String], "ghost")
	var machine := MachineAssembler.build(session.blueprint, _defs(), Transform3D(Basis.IDENTITY, Vector3(0, 5000, 0)))
	tree.root.add_child(machine)
	for part in machine.parts:
		if part.entry.cell == Vector3i(1, 0, 0):
			assert_eq(_visible_tiers(part), ["Tier2"] as Array[String], "live part")
	machine.free()
	session.free()
