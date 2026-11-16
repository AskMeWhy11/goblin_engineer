class_name ResultScreen
extends CanvasLayer
## "Task complete" screen. The simulation keeps running underneath.

## The text shown to the player (also read by tests).
var summary := ""

var _session: LevelSession
var _text: Label


func setup(session: LevelSession) -> void:
	_session = session
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	holder.grow_vertical = Control.GROW_DIRECTION_BOTH
	holder.add_theme_constant_override("margin_right", 24)
	root.add_child(holder)
	var box := UiKit.panel(holder, 18)
	UiKit.tag(box, "Задача выполнена!", 28)
	_text = UiKit.label(box, "", 18)
	_text.custom_minimum_size = Vector2(420, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.button(box, "В сборку", session.enter_build, 420)
	UiKit.button(box, "Ещё раз с тем же зерном", func() -> void: session.enter_sim(session.last_seed), 420)
	UiKit.button(box, "К уровням", Game.goto_level_select, 420)
	visible = false


func show_result(machine: Machine, failure_log: Array[String]) -> void:
	var report := RiskCalculator.evaluate(_session.blueprint, PartCatalog.defs)
	var pilot := machine.pilot()
	var lines: Array[String] = [
		"Время: %.1f с" % machine.sim_time,
		"Стоимость машины: %d из %d" % [report.cost, _session.level.budget],
		"Зерно: %d" % _session.last_seed,
		"Испытатель выжил" if pilot != null and pilot.is_alive() else "Испытатель не выжил",
		"",
		"Журнал отказов:",
	]
	if failure_log.is_empty():
		lines.append("ни одного — подозрительно надёжная машина")
	else:
		lines.append_array(failure_log)
	summary = "\n".join(lines)
	_text.text = summary
	visible = true
