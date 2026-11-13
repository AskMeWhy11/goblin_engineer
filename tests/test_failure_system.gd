extends TestCase

const DT := 1.0 / 60.0

var _machine: Machine
var _events: Array = []  # [cell, mode, tick]
var _tick := 0


func _def(rates: Vector3, always_loaded := true, margin := 1.0) -> PartDef:
	var real: PartDef = tree.root.get_node("PartCatalog").get_def(&"block")
	var tier := QualityTier.new()
	tier.rates = rates
	tier.strength_margin = margin
	var def := PartDef.new()
	def.id = &"probe"
	def.display_name = "Проба"
	def.scene = real.scene
	def.mass = 5.0
	def.tiers = [tier]
	def.always_loaded = always_loaded
	return def


## Core plus two probe parts in a row; the failure system is stepped by hand.
func _build(def: PartDef, seed: int) -> FailureSystem:
	var bp := Blueprint.with_core()
	for x in [1, 2]:
		var e := BlueprintEntry.new()
		e.part_id = &"probe"
		e.cell = Vector3i(x, 0, 0)
		bp.add(e)
	var catalog := {&"core": tree.root.get_node("PartCatalog").get_def(&"core"), &"probe": def}
	_machine = MachineAssembler.build(bp, catalog, Transform3D(Basis.IDENTITY, Vector3(0, 900, 0)))
	_machine.set_physics_process(false)
	for p in _machine.parts:
		p.freeze = true
	tree.root.add_child(_machine)
	_events = []
	_tick = 0
	_machine.part_failed.connect(func(part: PartBody, mode: int, _time: float) -> void:
		_events.append([part.entry.cell, mode, _tick]))
	var fs := FailureSystem.new()
	fs.set_physics_process(false)
	_machine.add_child(fs)
	fs.setup(_machine, seed)
	return fs


func _run(fs: FailureSystem, ticks: int) -> void:
	for _i in ticks:
		_tick += 1
		fs.step(DT)


func _probe(x: int) -> PartBody:
	for p in _machine.parts:
		if p.entry.cell == Vector3i(x, 0, 0):
			return p
	return null


func test_same_seed_same_first_failure() -> void:
	var first: Array = []
	for attempt in 2:
		var fs := _build(_def(Vector3(0.3, 0.3, 0.0)), 77)
		_run(fs, 3000)
		assert_true(not _events.is_empty(), "something failed")
		if not _events.is_empty():
			first.append(_events[0])
		_machine.free()
	assert_eq(first.size(), 2)
	if first.size() == 2:
		assert_eq(first[0], first[1])


func test_different_seeds_differ() -> void:
	var ticks := {}
	for seed in 6:
		var fs := _build(_def(Vector3(0.0, 0.3, 0.0)), seed)
		_run(fs, 3000)
		if not _events.is_empty():
			ticks[_events[0][2]] = true
		_machine.free()
	assert_true(ticks.size() >= 4, str(ticks.keys()))


func test_idle_active_part_never_fails() -> void:
	var fs := _build(_def(Vector3(1, 1, 1), false), 3)
	_run(fs, 6000)
	assert_eq(_events.size(), 0)
	_machine.free()


func test_break_detaches_and_emits_once() -> void:
	var fs := _build(_def(Vector3(0, 1000, 0)), 3)
	_run(fs, 1)
	assert_eq(_probe(1).state, PartBody.State.DETACHED)
	var for_first := _events.filter(func(e: Array) -> bool: return e[0] == Vector3i(1, 0, 0))
	assert_eq(for_first.size(), 1)
	assert_eq(for_first[0][1], FailureMode.BREAK)
	_machine.free()


func test_detached_part_stops_ticking() -> void:
	var fs := _build(_def(Vector3(0, 1000, 0)), 3)
	_run(fs, 1)
	var count := _events.size()
	assert_eq(count, 2, "both probes broke on the first tick")
	_run(fs, 600)
	assert_eq(_events.size(), count)
	_machine.free()


func test_malfunctioned_part_can_still_break() -> void:
	var fs := _build(_def(Vector3(1000, 0.5, 0)), 3)
	_run(fs, 1)
	assert_eq(_probe(1).state, PartBody.State.MALFUNCTIONED)
	_run(fs, 6000)
	var modes := _events.filter(func(e: Array) -> bool: return e[0] == Vector3i(1, 0, 0)).map(
			func(e: Array) -> int: return e[1])
	assert_eq(modes, [FailureMode.MALFUNCTION, FailureMode.BREAK])
	assert_eq(_probe(1).state, PartBody.State.DETACHED)
	_machine.free()


func test_shock_breaks_a_weak_part_after_the_grace_period() -> void:
	var fs := _build(_def(Vector3(0, 0.0001, 0), true, 0.8), 3)
	_run(fs, int(SimTuning.SHAKE_GRACE / DT) + 5)
	assert_eq(_events.size(), 0, "quiet so far")
	_probe(1).linear_velocity = Vector3(0, -50, 0)
	_run(fs, 1)
	assert_eq(_probe(1).state, PartBody.State.DETACHED)
	assert_eq(_probe(2).state, PartBody.State.OK, "only the shaken part breaks")
	_machine.free()


func test_shock_during_the_launch_grace_period_is_ignored() -> void:
	var fs := _build(_def(Vector3(0, 0.0001, 0), true, 0.8), 3)
	_run(fs, 2)
	_probe(1).linear_velocity = Vector3(0, -50, 0)
	_run(fs, 2)
	assert_eq(_events.size(), 0)
	_machine.free()


func test_failure_text_per_mode() -> void:
	var fs := _build(_def(Vector3(0, 0.0001, 0)), 3)
	var part := _probe(1)
	assert_eq(SimHud.failure_line(part, FailureMode.MALFUNCTION, 12.44), "12.4 с — Проба: разболтался")
	assert_eq(SimHud.failure_line(part, FailureMode.BREAK, 3.0), "3.0 с — Проба: поломка")
	assert_eq(SimHud.failure_line(part, FailureMode.EXPLODE, 0.52), "0.5 с — Проба: ВЗРЫВ")
	assert_true(fs != null)
	_machine.free()
