class_name RiskBar
extends Control
## Machine risk as three coloured segments (weighted contributions) with the level threshold mark.

var caption := ""

var _parts: Array[float] = [0.0, 0.0, 0.0]  # weighted: malfunction, break, explode
var _risk_min := 0.0
var _label: Label


func _init() -> void:
	custom_minimum_size = Vector2(420, 52)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", UiKit.INK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func show_report(report: RiskReport, risk_min: float) -> void:
	_parts = [
		report.malfunction * FailureMode.WEIGHTS[FailureMode.MALFUNCTION],
		report.breakage * FailureMode.WEIGHTS[FailureMode.BREAK],
		report.explosion * FailureMode.WEIGHTS[FailureMode.EXPLODE],
	]
	_risk_min = risk_min
	caption = "Риск: %s из %s %%/с" % [UiKit.percent(report.total()), UiKit.percent(risk_min)]
	_label.text = caption
	var enough := report.total() >= risk_min - 1e-9
	_label.add_theme_color_override("font_color", UiKit.TEXT if enough else UiKit.WARN)
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(0, 28, size.x, 20)
	draw_rect(bar.grow(2.0), UiKit.INK)
	var total: float = _parts[0] + _parts[1] + _parts[2]
	var full := maxf(_risk_min * 2.0, total * 1.15)
	if full <= 0.0:
		return
	var colors: Array[Color] = [UiKit.COLOR_MALFUNCTION, UiKit.COLOR_BREAK, UiKit.COLOR_EXPLODE]
	var x := 0.0
	for i in 3:
		var w: float = _parts[i] / full * bar.size.x
		draw_rect(Rect2(x, bar.position.y, w, bar.size.y), colors[i])
		x += w
	var mark := _risk_min / full * bar.size.x
	draw_line(Vector2(mark, bar.position.y - 4), Vector2(mark, bar.end.y + 4), UiKit.TEXT, 3.0)
