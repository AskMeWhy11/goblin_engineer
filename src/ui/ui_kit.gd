class_name UiKit
## Small helpers so every screen is built the same way: battered wood panels, crooked plank
## buttons, parchment tags.

const BG := Color(0.13, 0.17, 0.12)
## Headline text on wood.
const ACCENT := Color("f0c860")
const TEXT := Color("f3e2c0")
const WARN := Color("ff9a78")
const INK := Color("2e1c10")
const COLOR_MALFUNCTION := Color(0.95, 0.85, 0.2)
const COLOR_BREAK := Color(0.95, 0.55, 0.15)
const COLOR_EXPLODE := Color(0.9, 0.2, 0.15)

const PLANK_COLORS: Array[Color] = [Color("7a5232"), Color("86603a"), Color("6e4a2c")]
const PLANK_RED := Color("c0503c")
const PLANK_DISABLED := Color("3f2c1c")


## Full-screen backdrop. The default is a wall of dark planks; any other colour is a flat fill
## (the pause menu dims the game with a translucent one).
static func background(parent: Control, color := BG) -> Control:
	var back: Control
	if color == BG:
		var wall := WoodBackdrop.new()
		wall.wall = true
		wall.seed_value = 77
		back = wall
	else:
		var rect := ColorRect.new()
		rect.color = color
		back = rect
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(back)
	return back


## A vertical box centered on the screen.
static func centered_column(parent: Control, separation := 16) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	center.add_child(box)
	return box


static func label(parent: Node, text: String, size := 22, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l


## A parchment tag: the heading of a panel.
static func tag(parent: Node, text: String, size := 18) -> WoodTag:
	var t := WoodTag.new(text, size)
	parent.add_child(t)
	return t


## A plank button. The same text always gives the same plank (colour and slant).
static func button(parent: Node, text: String, on_press: Callable, min_width := 260) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 44)
	b.focus_mode = Control.FOCUS_NONE
	var roll := absi(hash(text))
	var skew := ((roll % 5) - 2) * 0.045
	if skew == 0.0:
		skew = 0.06
	var wood := PLANK_COLORS[(roll / 5) % PLANK_COLORS.size()]
	b.add_theme_stylebox_override("normal", _plank(wood, skew))
	b.add_theme_stylebox_override("hover", _plank(wood.lightened(0.14), skew))
	b.add_theme_stylebox_override("pressed", _plank(PLANK_RED, skew))
	b.add_theme_stylebox_override("hover_pressed", _plank(PLANK_RED.lightened(0.1), skew))
	b.add_theme_stylebox_override("disabled", _plank(PLANK_DISABLED, skew))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, TEXT)
	b.add_theme_color_override("font_disabled_color", Color(TEXT, 0.4))
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


static func _plank(color: Color, skew: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(2)
	box.border_width_bottom = 4
	box.set_corner_radius_all(3)
	box.skew = Vector2(skew, 0.0)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 8
	return box


## A wooden panel; returns the box to put content into.
static func panel(parent: Node, padding := 14) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(p)
	var back := WoodBackdrop.new()
	back.seed_value = 1 + parent.get_child_count() * 31 + padding
	p.add_child(back)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding + 6)
	p.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return box


## Styles a ProgressBar as a groove cut into the wood, filled with `color`.
static func style_bar(bar: ProgressBar, color: Color) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = INK
	groove.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	fill.set_border_width_all(2)
	fill.border_color = INK
	bar.add_theme_stylebox_override("background", groove)
	bar.add_theme_stylebox_override("fill", fill)


static func percent(rate: float) -> String:
	return "%.1f" % (rate * 100.0)
