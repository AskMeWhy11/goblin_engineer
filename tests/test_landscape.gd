extends TestCase

const AREA := Rect2(-20, -18, 100, 36)


func _game() -> Node:
	return tree.root.get_node("Game")


func test_decor_positions_are_stable_for_a_seed() -> void:
	var a := LevelKit.decor_positions(5, AREA, 30, 6.0)
	var b := LevelKit.decor_positions(5, AREA, 30, 6.0)
	var c := LevelKit.decor_positions(6, AREA, 30, 6.0)
	assert_eq(a, b)
	assert_true(a != c)
	assert_true(a.size() >= 20, "placed %d of 30" % a.size())


func test_decor_keeps_the_road_and_excluded_zones_clear() -> void:
	var hole := Rect2(10, -18, 12, 36)
	var spots := LevelKit.decor_positions(9, AREA, 60, 6.0, [hole])
	assert_true(spots.size() >= 20)
	for p in spots:
		assert_true(absf(p.z) >= 6.0, "road is clear: %s" % p)
		assert_true(AREA.has_point(Vector2(p.x, p.z)), "inside the area: %s" % p)
		assert_true(not hole.has_point(Vector2(p.x, p.z)), "outside the excluded zone: %s" % p)
		assert_eq(p.y, 0.0)


func test_decor_does_not_clump() -> void:
	var spots := LevelKit.decor_positions(2, AREA, 40, 6.0)
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			assert_true(spots[i].distance_to(spots[j]) >= LevelKit.DECOR_MIN_GAP - 0.001)


func test_impossible_request_returns_what_fits() -> void:
	var tiny := Rect2(0, 7, 2, 2)
	var spots := LevelKit.decor_positions(1, tiny, 500, 6.0)
	assert_true(spots.size() <= 4)
	assert_eq(LevelKit.decor_positions(1, Rect2(0, 0, 4, 4), 10, 6.0).size(), 0, "nothing fits inside the road")


func test_scattered_decor_never_collides() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	LevelKit.scatter(holder, 3, AREA, 25, 6.0)
	var decor := tree.get_nodes_in_group(&"decor")
	assert_true(decor.size() >= 15)
	assert_eq(holder.find_children("*", "CollisionObject3D", true, false).size(), 0)
	holder.free()


func test_lighting_gives_sky_fog_and_a_soft_sun() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	LevelKit.lighting(holder)
	var world := holder.find_children("*", "WorldEnvironment", true, false)
	var suns := holder.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(world.size(), 1)
	assert_eq(suns.size(), 1)
	if world.size() == 1:
		var env: Environment = world[0].environment
		assert_eq(env.background_mode, Environment.BG_SKY)
		assert_true(env.sky != null and env.sky.sky_material is ProceduralSkyMaterial)
		assert_true(env.fog_enabled)
		assert_true(env.fog_light_color.get_luminance() > 0.7, "pale fog")
	if suns.size() == 1:
		assert_true(suns[0].shadow_enabled)
	holder.free()


func test_slab_top_is_at_the_given_height_and_has_a_cliff() -> void:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	LevelKit.slab(holder, Vector2(40, 20), Vector3(5, 0, 0))
	await tree.physics_frame
	await tree.physics_frame
	var space := holder.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(Vector3(5, 10, 0), Vector3(5, -50, 0), Layers.WORLD)
	var hit := space.intersect_ray(down)
	assert_true(not hit.is_empty())
	if not hit.is_empty():
		assert_almost(hit.position.y, 0.0, 0.01, "walkable top")
	var outside := PhysicsRayQueryParameters3D.create(Vector3(30, 10, 0), Vector3(30, -50, 0), Layers.WORLD)
	assert_true(space.intersect_ray(outside).is_empty(), "nothing beyond the edge")
	var side := PhysicsRayQueryParameters3D.create(Vector3(40, -3, 0), Vector3(5, -3, 0), Layers.WORLD)
	assert_true(not space.intersect_ray(side).is_empty(), "the slab has depth: a cliff below the grass")
	holder.free()
	await tree.physics_frame


func test_every_level_is_dressed() -> void:
	for level: LevelDef in _game().levels:
		var root: Node3D = level.scene.instantiate()
		tree.root.add_child(root)
		var decor := root.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n.is_in_group(&"decor"))
		assert_true(decor.size() >= 12, "%s has %d decor pieces" % [level.id, decor.size()])
		assert_eq(root.find_children("*", "WorldEnvironment", true, false).size(), 1, str(level.id))
		var origin := root.get_node("BuildOrigin") as Node3D
		for piece: Node3D in decor:
			var flat := Vector2(piece.global_position.x - origin.global_position.x, piece.global_position.z)
			assert_true(flat.length() > 5.0, "%s: decor away from the build volume" % level.id)
		root.free()
