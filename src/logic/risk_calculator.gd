class_name RiskCalculator
## Computes machine cost and risk from a blueprint (design doc 6.4).


## catalog: StringName -> PartDef. Unknown part ids are ignored.
static func evaluate(bp: Blueprint, catalog: Dictionary) -> RiskReport:
	var report := RiskReport.new()
	for e in bp.entries:
		var def: PartDef = catalog.get(e.part_id)
		if def == null:
			continue
		var tier := def.tiers[clampi(e.tier, 0, def.tiers.size() - 1)]
		report.cost += roundi(def.base_price * tier.price_mult)
		report.malfunction += tier.rates.x
		report.breakage += tier.rates.y
		report.explosion += tier.rates.z
	return report


## Returns "" when the machine may launch, otherwise the reason shown to the player.
static func launch_blocker(report: RiskReport, level: LevelDef) -> String:
	if report.cost > level.budget:
		return "Бюджет превышен на %d" % (report.cost - level.budget)
	if report.total() < level.risk_min - 1e-9:
		return "Риск ниже порога: %.1f из %.1f %%/с" % [report.total() * 100.0, level.risk_min * 100.0]
	return ""
