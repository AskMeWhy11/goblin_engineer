extends RefCounted
## Performance check setup: fills two layers of the build volume with blocks (about 100 parts).


static func setup(session: Node) -> void:
	var build_mode: BuildMode = session.build_mode
	build_mode.clear_all()
	build_mode.selected_part = PartCatalog.get_def(&"block")
	# Sweep outwards from the core several times so every cell finds a neighbour.
	for _pass in 8:
		for y in [0, 1]:
			for x in range(-3, 4):
				for z in range(-3, 4):
					build_mode.selected_tier = absi(x + z + y) % 3
					build_mode.try_place(Vector3i(x, y, z))
	build_mode.selected_part = null
	print("SHOT parts=", session.blueprint.entries.size())
