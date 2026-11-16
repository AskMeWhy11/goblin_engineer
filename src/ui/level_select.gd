extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.background(self)
	var box := UiKit.centered_column(self, 20)
	var title := UiKit.label(box, "Выбор уровня", 40, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for level in Game.levels:
		_card(row, level)
	UiKit.button(box, "Назад", Game.goto_main_menu).size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _card(parent: Node, level: LevelDef) -> void:
	var card := UiKit.panel(parent)
	card.custom_minimum_size = Vector2(300, 0)
	UiKit.tag(card, level.title, 24)
	var task := UiKit.label(card, level.task_text, 18)
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task.custom_minimum_size = Vector2(280, 56)
	UiKit.label(card, "Бюджет: %d" % level.budget, 18)
	UiKit.label(card, "Риск не ниже: %s %%/с" % UiKit.percent(level.risk_min), 18)
	UiKit.button(card, "Играть", Game.start_level.bind(level))
