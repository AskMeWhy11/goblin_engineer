extends RefCounted
## Builds a simple test cart in a LevelSession (used by screenshots and simulation tests).
## Chassis of blocks along X, four junk motor wheels on the sides.


static func setup(session: Node) -> void:
	build(session, 2)


static func build(session: LevelSession, wheel_tier: int) -> void:
	var build_mode := session.build_mode
	build_mode.clear_all()
	build_mode.selected_tier = 0
	build_mode.selected_part = PartCatalog.get_def(&"block")
	for cell: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(2, 0, 0), Vector3i(-2, 0, 0)]:
		build_mode.try_place(cell)
	build_mode.selected_tier = wheel_tier
	build_mode.selected_part = PartCatalog.get_def(&"motor_wheel")
	for cell: Vector3i in [Vector3i(2, 0, 1), Vector3i(2, 0, -1), Vector3i(-2, 0, 1), Vector3i(-2, 0, -1)]:
		build_mode.try_place(cell)
	build_mode.selected_part = null
