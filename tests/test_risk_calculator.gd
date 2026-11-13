extends TestCase


func _part(id: StringName, price: int, rates: Vector3, price_mult := 1.0) -> PartDef:
	var tier := QualityTier.new()
	tier.price_mult = price_mult
	tier.rates = rates
	tier.strength_margin = 1.0
	var def := PartDef.new()
	def.id = id
	def.base_price = price
	def.tiers = [tier]
	return def


func _bp(ids: Array) -> Blueprint:
	var bp := Blueprint.with_core()
	for i in ids.size():
		var e := BlueprintEntry.new()
		e.part_id = ids[i]
		e.cell = Vector3i(1 + i, 0, 0)
		bp.add(e)
	return bp


func _level(budget: int, risk_min: float) -> LevelDef:
	var level := LevelDef.new()
	level.budget = budget
	level.risk_min = risk_min
	return level


func test_spec_equivalence_3_2_1() -> void:
	var cat := {
		&"core": _part(&"core", 0, Vector3.ZERO),
		&"boom": _part(&"boom", 10, Vector3(0, 0, 0.03)),
		&"snap": _part(&"snap", 10, Vector3(0, 0.03, 0)),
		&"stall": _part(&"stall", 10, Vector3(0.03, 0, 0)),
	}
	assert_almost(RiskCalculator.evaluate(_bp([&"boom"]), cat).total(), 0.03, 1e-6)
	assert_almost(RiskCalculator.evaluate(_bp([&"snap", &"snap"]), cat).total(), 0.03, 1e-6)
	assert_almost(RiskCalculator.evaluate(_bp([&"stall", &"stall", &"stall"]), cat).total(), 0.03, 1e-6)


func test_report_keeps_raw_sums_per_mode() -> void:
	var cat := {
		&"core": _part(&"core", 0, Vector3.ZERO),
		&"mix": _part(&"mix", 10, Vector3(0.03, 0.02, 0.01)),
	}
	var r := RiskCalculator.evaluate(_bp([&"mix", &"mix"]), cat)
	assert_almost(r.malfunction, 0.06, 1e-6)
	assert_almost(r.breakage, 0.04, 1e-6)
	assert_almost(r.explosion, 0.02, 1e-6)


func test_cost_uses_tier_multiplier() -> void:
	var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 10, Vector3.ZERO, 0.3)}
	assert_eq(RiskCalculator.evaluate(_bp([&"b", &"b"]), cat).cost, 6)


func test_core_only_is_blocked_by_risk() -> void:
	var cat := {&"core": _part(&"core", 0, Vector3.ZERO)}
	var msg := RiskCalculator.launch_blocker(RiskCalculator.evaluate(Blueprint.with_core(), cat), _level(100, 0.01))
	assert_eq(msg, "Риск ниже порога: 0.0 из 1.0 %/с")


func test_over_budget_message() -> void:
	var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 60, Vector3(0, 0, 0.05))}
	var msg := RiskCalculator.launch_blocker(RiskCalculator.evaluate(_bp([&"b", &"b"]), cat), _level(100, 0.01))
	assert_eq(msg, "Бюджет превышен на 20")


func test_budget_message_wins_when_both_fail() -> void:
	var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 200, Vector3.ZERO)}
	var msg := RiskCalculator.launch_blocker(RiskCalculator.evaluate(_bp([&"b"]), cat), _level(100, 0.01))
	assert_eq(msg, "Бюджет превышен на 100")


func test_exactly_at_limits_is_allowed() -> void:
	var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 100, Vector3(0, 0, 0.01))}
	var msg := RiskCalculator.launch_blocker(RiskCalculator.evaluate(_bp([&"b"]), cat), _level(100, 0.01))
	assert_eq(msg, "")
