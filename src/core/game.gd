extends Node
## Autoload "Game": level list, per-level blueprints for this session, scene transitions.

const LEVELS_DIR := "res://data/levels"
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const LEVEL_SESSION := "res://scenes/level_session.tscn"

var levels: Array[LevelDef] = []
var current_level: LevelDef

## level id -> Blueprint. Lives in memory only (no saving in the prototype).
var _blueprints: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_actions()
	levels = load_levels()


static func load_levels(dir := LEVELS_DIR) -> Array[LevelDef]:
	var result: Array[LevelDef] = []
	for file in DirAccess.get_files_at(dir):
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var level := load(dir + "/" + name) as LevelDef
		if level != null:
			result.append(level)
	result.sort_custom(func(a: LevelDef, b: LevelDef) -> bool: return String(a.id) < String(b.id))
	return result


func blueprint_for(level: LevelDef) -> Blueprint:
	if not _blueprints.has(level.id):
		_blueprints[level.id] = Blueprint.with_core()
	return _blueprints[level.id]


func goto_main_menu() -> void:
	_change_scene(MAIN_MENU)


func goto_level_select() -> void:
	_change_scene(LEVEL_SELECT)


func start_level(level: LevelDef) -> void:
	current_level = level
	_change_scene(LEVEL_SESSION)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _register_actions() -> void:
	_key_action(&"toggle_sim", KEY_TAB)
	_key_action(&"pause", KEY_ESCAPE)
	_key_action(&"repeat_seed", KEY_F5)
	_key_action(&"build_rotate_y", KEY_R)
	_key_action(&"build_rotate_x", KEY_T)
	if not InputMap.has_action(&"build_delete"):
		InputMap.add_action(&"build_delete")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(&"build_delete", click)


func _key_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
