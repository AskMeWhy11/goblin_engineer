class_name Machine
extends Node3D
## The only access point to a live machine. Code outside this file and MachineAssembler never
## touches joints, so the physical representation can change without rewriting the rest.

signal part_failed(part: PartBody, mode: int, time: float)

var parts: Array[PartBody] = []
var sim_time := 0.0
## Seeded per launch; use it for every random choice inside the simulation.
var rng := RandomNumberGenerator.new()

## Each link is [PartBody a, PartBody b, Joint3D joint].
var _links: Array = []


func _physics_process(delta: float) -> void:
	sim_time += delta


func core() -> PartBody:
	for part in parts:
		if part.entry.part_id == Blueprint.CORE_ID:
			return part
	return null


func attached_parts() -> Array[PartBody]:
	var result: Array[PartBody] = []
	for part in parts:
		if part.is_attached():
			result.append(part)
	return result


func joint_count() -> int:
	return _links.size()


func joints_of(part: PartBody) -> Array[Joint3D]:
	var result: Array[Joint3D] = []
	for link in _links:
		if link[0] == part or link[1] == part:
			result.append(link[2])
	return result


## Parts directly joined to `part`.
func linked_parts(part: PartBody) -> Array[PartBody]:
	var result: Array[PartBody] = []
	for link in _links:
		if link[0] == part:
			result.append(link[1])
		elif link[1] == part:
			result.append(link[0])
	return result


func add_part(part: PartBody) -> void:
	part.machine = self
	parts.append(part)
	add_child(part)


## Registers a joint between two parts. The joint must already be positioned.
func link(a: PartBody, b: PartBody, joint: Joint3D) -> void:
	add_child(joint)
	joint.node_a = NodePath("../" + a.name)
	joint.node_b = NodePath("../" + b.name)
	_links.append([a, b, joint])


## Replaces the joint between two linked parts (used by malfunction effects).
func replace_joint(old_joint: Joint3D, new_joint: Joint3D) -> void:
	for link in _links:
		if link[2] == old_joint:
			new_joint.transform = old_joint.transform
			add_child(new_joint)
			new_joint.node_a = NodePath("../" + link[0].name)
			new_joint.node_b = NodePath("../" + link[1].name)
			link[2] = new_joint
			old_joint.queue_free()
			return


## Removes every joint of the part: it falls off the machine.
func detach(part: PartBody) -> void:
	if not part.is_attached():
		return
	_remove_links_of(part)
	part.state = PartBody.State.DETACHED
	update_layers()
	part.on_detached()


## Applies a failure reported by the FailureSystem (or caused by an explosion nearby).
func apply_failure(part: PartBody, mode: int) -> void:
	if not part.is_attached():
		return
	match mode:
		FailureMode.MALFUNCTION:
			if part.state != PartBody.State.OK:
				return
			part.state = PartBody.State.MALFUNCTIONED
			part.apply_malfunction()
		FailureMode.BREAK:
			detach(part)
		FailureMode.EXPLODE:
			explode(part)
	part_failed.emit(part, mode, sim_time)


## Blows the part up. Until explosions are implemented this only detaches it.
func explode(part: PartBody) -> void:
	detach(part)


func _remove_links_of(part: PartBody) -> void:
	for link in _links.duplicate():
		if link[0] == part or link[1] == part:
			link[2].queue_free()
			_links.erase(link)


## Parts still reachable from the core stay on the MACHINE layer (they do not collide with each
## other); everything else becomes debris that collides with the machine and the world.
func update_layers() -> void:
	var reached := {}
	var start := core()
	if start != null and start.is_attached():
		reached[start] = true
		var queue: Array[PartBody] = [start]
		while not queue.is_empty():
			var current: PartBody = queue.pop_back()
			for other in linked_parts(current):
				if not reached.has(other):
					reached[other] = true
					queue.append(other)
	for part in parts:
		if reached.has(part):
			part.collision_layer = Layers.MACHINE
			part.collision_mask = Layers.WORLD | Layers.DEBRIS
		else:
			part.collision_layer = Layers.DEBRIS
			part.collision_mask = Layers.WORLD | Layers.MACHINE | Layers.DEBRIS
