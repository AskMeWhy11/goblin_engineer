extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.background(self)
	var box := UiKit.centered_column(self)
	var title := UiKit.label(box, "Goblin Engineer", 64, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tagline := UiKit.label(box, "Надёжно — значит, недостаточно смело", 20, Color(0.8, 0.8, 0.7))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(Control.new())
	UiKit.button(box, "Играть", Game.goto_level_select)
	UiKit.button(box, "Выход", func() -> void: get_tree().quit())
