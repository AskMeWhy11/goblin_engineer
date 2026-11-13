class_name Machine
extends Node3D
## The only access point to a live machine. Code outside this file and MachineAssembler never
## touches joints, so the physical representation can change without rewriting the rest.

signal part_failed(part: PartBody, mode: int, time: float)
## For effects: an explosion with real blast power happened.
signal exploded(position: Vector3, power: float, radius: float)

var parts: Array[PartBody] = []
var sim_time := 0.0
## Seeded per launch; use it for every random choice inside the simulation.
var rng := RandomNumberGenerator.new()

## Each link is [PartBody a, PartBody b, Joint3D joint].
var _links: Array = []
## Parts whose chain fuse is already burning.
var _fused: Dictionary = {}


func _physics_process(delta: float) -> void:
	sim_time += delta


func core() -> PartBody:
	for part in parts:
		if part.entry.part_id == Blueprint.CORE_ID:
			return part
	return null


func pilot() -> Pilot:
	var seat := core()
	return seat.get_node_or_null("Pilot") as Pilot if seat != null else null


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
			explode(part)  # emits part_failed itself
			return
	part_failed.emit(part, mode, sim_time)


## Destroys the part and, if it has blast power, hits everything around it (design doc 6.1).
## Safe to call twice: a destroyed part does nothing.
func explode(part: PartBody) -> void:
	if part.state == PartBody.State.DESTROYED:
		return
	var center := part.global_position
	var power := part.def.explosion_power
	var radius := part.def.explosion_radius
	_remove_links_of(part)
	part.state = PartBody.State.DESTROYED
	part.visible = false
	part.collision_layer = 0
	part.collision_mask = 0
	part.freeze = true
	part.process_mode = Node.PROCESS_MODE_DISABLED
	update_layers()
	part_failed.emit(part, FailureMode.EXPLODE, sim_time)
	if power <= 0.0 or radius <= 0.0:
		return
	exploded.emit(center, power, radius)

	for other in parts:
		if other == part or other.state == PartBody.State.DESTROYED:
			continue
		var distance := center.distance_to(other.global_position)
		if distance >= radius:
			continue
		_push(other, center, power * (1.0 - distance / radius))
		if other.is_attached() and distance < radius * SimTuning.BLAST_TEAR_FRACTION:
			apply_failure(other, FailureMode.BREAK)
		if other.detonates_in_chain() and not _fused.has(other):
			_fused[other] = true
			_light_fuse(other)

	var seat := core()
	var goblin := pilot()
	if seat != null and goblin != null and seat != part:
		seat.call(&"skip_next_impact")
		goblin.take_damage(Pilot.explosion_damage(power, radius, center.distance_to(seat.global_position)))

	_blast_world(center, power, radius)


## Runs `action` after `seconds`. The timer is a child node, so it dies with the machine and never
## fires into freed parts.
func after(seconds: float, action: Callable) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	timer.timeout.connect(func() -> void:
		timer.queue_free()
		action.call())
	add_child(timer)
	timer.start()


func _push(body: RigidBody3D, center: Vector3, impulse: float) -> void:
	var direction := body.global_position - center
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.UP
	body.apply_central_impulse(direction * impulse)


func _light_fuse(part: PartBody) -> void:
	after(SimTuning.CHAIN_FUSE, explode.bind(part))


## Pushes loose bodies of the level (cargo, projectiles) and damages destructible targets.
func _blast_world(center: Vector3, power: float, radius: float) -> void:
	if not is_inside_tree():
		return
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = Layers.WORLD | Layers.DEBRIS
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 64):
		var body := hit.collider as Node3D
		if body == null or body is PartBody:
			continue
		var strength := power * maxf(0.0, 1.0 - center.distance_to(body.global_position) / radius)
		if body.is_in_group(&"destructible"):
			body.call(&"take_hit", strength)
		if body is RigidBody3D and not (body as RigidBody3D).freeze:
			_push(body, center, strength)


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
