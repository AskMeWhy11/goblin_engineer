class_name SimHud
extends CanvasLayer
## Simulation interface: task, timer, seed, failure log.

const LOG_LINES := 6

## Every failure of the current launch, oldest first.
var failure_log: Array[String] = []

var _session: LevelSession
var _machine: Machine
var _timer_label: Label
var _log_label: Label
var _status_label: Label
var _health_bar: ProgressBar


func setup(session: LevelSession) -> void:
	_session = session
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.add_theme_constant_override("margin_top", 10)
	root.add_child(top)
	var box := UiKit.panel(top, 10)
	UiKit.label(box, "%s — %s" % [session.level.title, session.level.task_text], 20, UiKit.ACCENT)
	_timer_label = UiKit.label(box, "", 18)
	UiKit.label(box, "Здоровье испытателя", 14, Color(1, 1, 1, 0.7))
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(360, 14)
	_health_bar.show_percentage = false
	_health_bar.max_value = 100.0
	box.add_child(_health_bar)
	_status_label = UiKit.label(box, "", 22, UiKit.WARN)

	var left := MarginContainer.new()
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.grow_vertical = Control.GROW_DIRECTION_BEGIN
	left.add_theme_constant_override("margin_left", 12)
	left.add_theme_constant_override("margin_bottom", 12)
	root.add_child(left)
	var log_box := UiKit.panel(left, 10)
	UiKit.label(log_box, "Журнал отказов", 18, UiKit.ACCENT)
	_log_label = UiKit.label(log_box, "", 16)
	_log_label.custom_minimum_size = Vector2(420, 0)
	UiKit.label(log_box, "Tab — в сборку · F5 — повтор с тем же зерном · ПКМ — камера", 14, Color(1, 1, 1, 0.7))


func track(machine: Machine) -> void:
	_machine = machine
	failure_log.clear()
	_log_label.text = "пока всё цело"
	_status_label.text = ""
	set_health(100.0)
	machine.part_failed.connect(_on_part_failed)
	var pilot := machine.pilot()
	if pilot != null:
		pilot.health_changed.connect(set_health)
		pilot.died.connect(set_status.bind("Управление потеряно"))


func set_health(value: float) -> void:
	_health_bar.value = value


func set_status(text: String) -> void:
	_status_label.text = text


func status_text() -> String:
	return _status_label.text


func _process(_delta: float) -> void:
	if is_instance_valid(_machine):
		_timer_label.text = "Время: %.1f с · Зерно: %d" % [_machine.sim_time, _session.last_seed]


func _on_part_failed(part: PartBody, mode: int, time: float) -> void:
	failure_log.append(failure_line(part, mode, time))
	_log_label.text = "\n".join(failure_log.slice(maxi(0, failure_log.size() - LOG_LINES)))


static func failure_text(part: PartBody, mode: int) -> String:
	match mode:
		FailureMode.MALFUNCTION:
			return part.malfunction_text()
		FailureMode.BREAK:
			return "поломка"
	return "ВЗРЫВ"


static func failure_line(part: PartBody, mode: int, time: float) -> String:
	return "%.1f с — %s: %s" % [time, part.def.display_name, failure_text(part, mode)]


static func failure_color(mode: int) -> Color:
	match mode:
		FailureMode.MALFUNCTION:
			return UiKit.COLOR_MALFUNCTION
		FailureMode.BREAK:
			return UiKit.COLOR_BREAK
	return UiKit.COLOR_EXPLODE
