class_name PartPanel
extends PanelContainer
## Properties of the selected machine part: quality, keys, inversion.

## Emitted right before the entry is changed, so the editor can save an undo step.
signal before_edit
signal entry_edited(entry: BlueprintEntry)

var entry: BlueprintEntry

var _def: PartDef
var _box: VBoxContainer
## 0 = not capturing, 1 = positive key, 2 = negative key
var _capturing := 0


func _init() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var back := WoodBackdrop.new()
	back.seed_value = 404
	add_child(back)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	margin.add_child(_box)
	visible = false


func show_entry(new_entry: BlueprintEntry, def: PartDef) -> void:
	entry = new_entry
	_def = def
	_capturing = 0
	visible = entry != null and def != null and def.removable
	if visible:
		_rebuild()


func _rebuild() -> void:
	for child in _box.get_children():
		child.free()
	UiKit.tag(_box, _def.display_name)
	for i in _def.tiers.size():
		var tier := _def.tiers[i]
		var b := UiKit.button(_box, "%s — %d" % [tier.display_name, _def.price(i)], set_tier.bind(i), 220)
		b.toggle_mode = true
		b.button_pressed = i == entry.tier
	if _def.activation != PartDef.Activation.NONE:
		UiKit.button(_box, _key_text("Клавиша +", entry.key_positive, 1), _capture.bind(1), 220)
		if _def.activation == PartDef.Activation.HOLD:
			UiKit.button(_box, _key_text("Клавиша −", entry.key_negative, 2), _capture.bind(2), 220)
			var invert := CheckBox.new()
			invert.text = "Инверсия"
			invert.focus_mode = Control.FOCUS_NONE
			invert.add_theme_color_override("font_color", UiKit.TEXT)
			invert.add_theme_color_override("font_pressed_color", UiKit.TEXT)
			invert.add_theme_color_override("font_hover_color", UiKit.TEXT)
			invert.button_pressed = entry.inverted
			invert.toggled.connect(func(on: bool) -> void:
				before_edit.emit()
				entry.inverted = on
				entry_edited.emit(entry))
			_box.add_child(invert)


func _key_text(title: String, key: Key, slot: int) -> String:
	if _capturing == slot:
		return title + ": нажми клавишу…"
	return "%s: %s" % [title, OS.get_keycode_string(key) if key != KEY_NONE else "—"]


func set_tier(tier: int) -> void:
	before_edit.emit()
	entry.tier = tier
	entry_edited.emit(entry)
	_rebuild()


func _capture(slot: int) -> void:
	_capturing = slot
	_rebuild()


func _input(event: InputEvent) -> void:
	if _capturing == 0 or not (event is InputEventKey) or not event.pressed:
		return
	var key: Key = event.physical_keycode
	if key != KEY_ESCAPE:
		before_edit.emit()
		if _capturing == 1:
			entry.key_positive = key
		else:
			entry.key_negative = key
		entry_edited.emit(entry)
	_capturing = 0
	get_viewport().set_input_as_handled()
	_rebuild()
