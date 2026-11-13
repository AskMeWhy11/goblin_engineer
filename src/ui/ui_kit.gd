class_name UiKit
## Small helpers so every screen is built the same way.

const BG := Color(0.13, 0.17, 0.12)
const ACCENT := Color(0.75, 0.9, 0.35)
const WARN := Color(0.95, 0.35, 0.25)
const COLOR_MALFUNCTION := Color(0.95, 0.85, 0.2)
const COLOR_BREAK := Color(0.95, 0.55, 0.15)
const COLOR_EXPLODE := Color(0.9, 0.2, 0.15)


static func background(parent: Control, color := BG) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


## A vertical box centered on the screen.
static func centered_column(parent: Control, separation := 16) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	center.add_child(box)
	return box


static func label(parent: Node, text: String, size := 22, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, on_press: Callable, min_width := 260) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


static func panel(parent: Node, padding := 14) -> VBoxContainer:
	var p := PanelContainer.new()
	parent.add_child(p)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding)
	p.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return box


static func percent(rate: float) -> String:
	return "%.1f" % (rate * 100.0)
