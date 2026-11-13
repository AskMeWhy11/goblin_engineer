class_name MachineAssembler
## Turns a Blueprint into a live Machine: one body per entry, one joint per connected pair.

const _POSITIVE_DIRS: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]


## `origin` is the world transform of cell (0,0,0). The returned machine is not in the tree yet.
static func build(bp: Blueprint, catalog: Dictionary, origin: Transform3D) -> Machine:
	var machine := Machine.new()
	machine.name = "Machine"
	var by_cell := {}
	for entry in bp.entries:
		var def: PartDef = catalog.get(entry.part_id)
		if def == null:
			continue
		var part := def.scene.instantiate() as PartBody
		if part == null:
			push_error("Part scene of '%s' has no PartBody script" % entry.part_id)
			continue
		part.def = def
		part.entry = entry
		part.tier = def.tiers[clampi(entry.tier, 0, def.tiers.size() - 1)]
		part.mass = def.mass
		part.name = "Part_%d_%d_%d" % [entry.cell.x, entry.cell.y, entry.cell.z]
		part.transform = origin * Transform3D(Orientations.basis(entry.orientation), Vector3(entry.cell))
		PartVisuals.tint_tier(part, entry.tier)
		machine.add_part(part)
		by_cell[entry.cell] = part

	for cell: Vector3i in by_cell:
		var a: PartBody = by_cell[cell]
		for dir in _POSITIVE_DIRS:
			var b: PartBody = by_cell.get(cell + dir)
			if b == null or not BlueprintRules.connects(bp, catalog, cell, cell + dir):
				continue
			var joint := a.custom_joint_to(b)
			if joint != null:
				machine.link(b, a, joint)
				continue
			joint = b.custom_joint_to(a)
			if joint != null:
				machine.link(a, b, joint)
				continue
			joint = SimTuning.make_rigid_joint()
			joint.position = (a.position + b.position) / 2.0
			machine.link(a, b, joint)

	# Parts in touching cells never collide with each other, even after they break off:
	# oversized wheels and exact-fit shapes would otherwise fight their neighbours.
	for cell: Vector3i in by_cell:
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					var other: PartBody = by_cell.get(cell + Vector3i(dx, dy, dz))
					if other != null and other != by_cell[cell]:
						by_cell[cell].add_collision_exception_with(other)
	machine.update_layers()
	return machine
