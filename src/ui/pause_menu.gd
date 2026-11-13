class_name PauseMenu
extends CanvasLayer
## Esc menu. Works while the tree is paused.

var _root: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	UiKit.background(_root, Color(0, 0, 0, 0.6)).mouse_filter = Control.MOUSE_FILTER_STOP
	var box := UiKit.centered_column(_root)
	var title := UiKit.label(box, "Пауза", 40, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.button(box, "Продолжить", set_open.bind(false))
	UiKit.button(box, "К уровням", Game.goto_level_select)
	UiKit.button(box, "В главное меню", Game.goto_main_menu)
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func set_open(open: bool) -> void:
	_root.visible = open
	get_tree().paused = open


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		set_open(not is_open())
		get_viewport().set_input_as_handled()
