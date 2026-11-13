class_name BlueprintRules
## Placement and connectivity rules for blueprints. Pure logic.

const DIRECTIONS: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN,
		Vector3i.BACK, Vector3i.FORWARD]


static func _accepts(def: PartDef, orientation: int, world_dir: Vector3i) -> bool:
	if def.attach_faces.is_empty():
		return true
	for face in def.attach_faces:
		if Orientations.world_normal(orientation, face) == world_dir:
			return true
	return false


## True when cells a and b are face neighbours and both parts accept a connection on that face.
static func connects(bp: Blueprint, catalog: Dictionary, a: Vector3i, b: Vector3i) -> bool:
	var dir := b - a
	if not DIRECTIONS.has(dir):
		return false
	var ea := bp.get_at(a)
	var eb := bp.get_at(b)
	if ea == null or eb == null:
		return false
	var da: PartDef = catalog.get(ea.part_id)
	var db: PartDef = catalog.get(eb.part_id)
	if da == null or db == null:
		return false
	return _accepts(da, ea.orientation, dir) and _accepts(db, eb.orientation, -dir)


static func neighbors(bp: Blueprint, catalog: Dictionary, cell: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for dir in DIRECTIONS:
		if connects(bp, catalog, cell, cell + dir):
			result.append(cell + dir)
	return result


static func can_place(bp: Blueprint, catalog: Dictionary, part: PartDef, cell: Vector3i,
		orientation: int, level: LevelDef) -> bool:
	if bp.get_at(cell) != null:
		return false
	if not level.allowed_parts.has(part.id):
		return false
	var lo := level.volume_min
	var hi := level.volume_max
	if cell.x < lo.x or cell.y < lo.y or cell.z < lo.z or cell.x > hi.x or cell.y > hi.y or cell.z > hi.z:
		return false
	for dir in DIRECTIONS:
		var other := bp.get_at(cell + dir)
		if other == null:
			continue
		var other_def: PartDef = catalog.get(other.part_id)
		if other_def != null and _accepts(part, orientation, dir) \
				and _accepts(other_def, other.orientation, -dir):
			return true
	return false


## A part may be removed if it is removable and every remaining part still reaches the core.
static func can_remove(bp: Blueprint, catalog: Dictionary, cell: Vector3i) -> bool:
	var entry := bp.get_at(cell)
	if entry == null:
		return false
	var def: PartDef = catalog.get(entry.part_id)
	if def == null or not def.removable:
		return false
	var reached := {Vector3i.ZERO: true}
	var queue: Array[Vector3i] = [Vector3i.ZERO]
	while not queue.is_empty():
		var current: Vector3i = queue.pop_back()
		for n in neighbors(bp, catalog, current):
			if n != cell and not reached.has(n):
				reached[n] = true
				queue.append(n)
	return reached.size() == bp.entries.size() - 1
