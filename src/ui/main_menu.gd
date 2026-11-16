extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.background(self)
	var box := UiKit.centered_column(self)
	var title := UiKit.label(box, "Goblin Engineer", 64, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tagline := UiKit.label(box, "Надёжно — значит, недостаточно смело", 20, UiKit.TEXT)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(Control.new())
	UiKit.button(box, "Играть", Game.goto_level_select).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiKit.button(box, "Выход", func() -> void: get_tree().quit()).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
