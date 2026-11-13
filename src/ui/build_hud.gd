class_name BuildHud
extends CanvasLayer
## Build mode interface: palette, quality, budget and risk bars, launch button, part properties.

var launch_button: Button
var blocker_label: Label
var budget_label: Label
var risk_bar: RiskBar
var info_label: Label
var part_panel: PartPanel

var _session: LevelSession
var _build: BuildMode
var _budget_bar: ProgressBar
var _palette_buttons: Dictionary = {}  # PartDef (or null) -> Button
var _tier_buttons: Array[Button] = []
const INFO_HINT := "Наведи курсор на деталь, чтобы увидеть её свойства"

var _pinned_info := INFO_HINT


func setup(session: LevelSession, build: BuildMode) -> void:
	_session = session
	_build = build
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_palette(root)
	_build_top(root)
	_build_launch(root)
	_build_right(root)
	build.blueprint_changed.connect(refresh)
	build.entry_selected.connect(_on_entry_selected)
	build.hover_changed.connect(_on_hover)
	_select_part(null)
	refresh()


func refresh() -> void:
	var report := RiskCalculator.evaluate(_session.blueprint, PartCatalog.defs)
	var level := _session.level
	budget_label.text = "Бюджет: %d / %d" % [report.cost, level.budget]
	budget_label.add_theme_color_override("font_color", UiKit.WARN if report.cost > level.budget else Color.WHITE)
	_budget_bar.max_value = level.budget
	_budget_bar.value = minf(report.cost, level.budget)
	risk_bar.show_report(report, level.risk_min)
	var blocker := RiskCalculator.launch_blocker(report, level)
	launch_button.disabled = not blocker.is_empty()
	blocker_label.text = blocker


func _build_palette(root: Control) -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	holder.add_theme_constant_override("margin_left", 12)
	holder.add_theme_constant_override("margin_top", 48)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(column)
	var box := UiKit.panel(column, 10)
	UiKit.label(box, "Детали", 20, UiKit.ACCENT)
	_palette_button(box, null, "Выбор")
	for id in _session.level.allowed_parts:
		var def := PartCatalog.get_def(id)
		if def != null:
			_palette_button(box, def, def.display_name)
	UiKit.label(box, "Качество", 20, UiKit.ACCENT)
	var names := ["1 · Добротная", "2 · Сойдёт", "3 · Хлам"]
	for i in 3:
		var b := UiKit.button(box, names[i], _select_tier.bind(i), 220)
		b.toggle_mode = true
		_tier_buttons.append(b)
	_select_tier(0)
	UiKit.button(box, "Очистить", _build.clear_all, 220)


func _palette_button(box: Node, def: PartDef, text: String) -> void:
	var b := UiKit.button(box, text, _select_part.bind(def), 220)
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if def != null:
		b.mouse_entered.connect(func() -> void: _show_info(def, _build.selected_tier))
		b.mouse_exited.connect(func() -> void: info_label.text = _pinned_info)
	_palette_buttons[def] = b


func _build_top(root: Control) -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.add_theme_constant_override("margin_top", 10)
	root.add_child(holder)
	var box := UiKit.panel(holder, 10)
	UiKit.label(box, "%s — %s" % [_session.level.title, _session.level.task_text], 20, UiKit.ACCENT)
	budget_label = UiKit.label(box, "", 18)
	_budget_bar = ProgressBar.new()
	_budget_bar.show_percentage = false
	_budget_bar.custom_minimum_size = Vector2(420, 12)
	box.add_child(_budget_bar)
	risk_bar = RiskBar.new()
	box.add_child(risk_bar)


func _build_launch(root: Control) -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.add_theme_constant_override("margin_right", 12)
	holder.add_theme_constant_override("margin_bottom", 12)
	root.add_child(holder)
	var box := UiKit.panel(holder, 10)
	launch_button = UiKit.button(box, "Запуск (Tab)", func() -> void: _session.enter_sim(), 280)
	blocker_label = UiKit.label(box, "", 16, UiKit.WARN)
	var help := UiKit.label(box, "ЛКМ — поставить · ПКМ — удалить\nR / T — повернуть · 1 2 3 — качество\nСКМ или WASD, Q/E — камера", 14, Color(1, 1, 1, 0.7))
	help.custom_minimum_size = Vector2(280, 0)


func _build_right(root: Control) -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	holder.add_theme_constant_override("margin_right", 12)
	holder.add_theme_constant_override("margin_top", 48)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	holder.add_child(column)
	part_panel = PartPanel.new()
	part_panel.entry_edited.connect(func(entry: BlueprintEntry) -> void:
		_build.refresh_entry(entry)
		_on_entry_selected(entry))
	column.add_child(part_panel)
	var info_box := UiKit.panel(column, 10)
	info_label = UiKit.label(info_box, "", 15)
	info_label.custom_minimum_size = Vector2(300, 0)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _select_part(def: PartDef) -> void:
	_build.selected_part = def
	for key: Variant in _palette_buttons:
		_palette_buttons[key].button_pressed = key == def
	if def != null:
		_on_entry_selected(null)


func _select_tier(tier: int) -> void:
	_build.selected_tier = tier
	for i in _tier_buttons.size():
		_tier_buttons[i].button_pressed = i == tier


func _on_entry_selected(entry: BlueprintEntry) -> void:
	# Number keys change the tier in BuildMode directly; keep the buttons in sync.
	for i in _tier_buttons.size():
		_tier_buttons[i].button_pressed = i == _build.selected_tier
	var def: PartDef = PartCatalog.get_def(entry.part_id) if entry != null else null
	part_panel.show_entry(entry, def)
	_pinned_info = info_text(def, entry.tier) if def != null else INFO_HINT
	info_label.text = _pinned_info


func _on_hover(def: PartDef, tier: int) -> void:
	if def == null:
		info_label.text = _pinned_info
	else:
		_show_info(def, tier)


func _show_info(def: PartDef, tier: int) -> void:
	info_label.text = info_text(def, tier)


static func info_text(def: PartDef, tier_index: int) -> String:
	var i := clampi(tier_index, 0, def.tiers.size() - 1)
	var tier := def.tiers[i]
	var lines: Array[String] = ["%s (%s) — %d" % [def.display_name, tier.display_name, def.price(i)]]
	lines.append("Масса %d кг" % roundi(def.mass))
	if tier.rates == Vector3.ZERO:
		lines.append("Не отказывает")
	else:
		lines.append("Выход из строя %.2f %%/с" % (tier.rates.x * 100.0))
		lines.append("Поломка %.2f %%/с" % (tier.rates.y * 100.0))
		lines.append("Взрыв %.2f %%/с" % (tier.rates.z * 100.0))
		lines.append("Запас прочности %.1f" % tier.strength_margin)
	if def.explosion_power > 0.0:
		lines.append("Сила взрыва %d, радиус %d м" % [roundi(def.explosion_power), roundi(def.explosion_radius)])
	return "\n".join(lines)
