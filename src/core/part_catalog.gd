extends Node
## Autoload "PartCatalog": every PartDef from data/parts, by id.

const PARTS_DIR := "res://data/parts"

## StringName -> PartDef
var defs: Dictionary = {}


func _ready() -> void:
	defs = load_all()


func get_def(id: StringName) -> PartDef:
	return defs.get(id)


static func load_all(dir := PARTS_DIR) -> Dictionary:
	var result := {}
	for file in DirAccess.get_files_at(dir):
		# Exported builds list resources as "<name>.tres.remap".
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var def := load(dir + "/" + name) as PartDef
		if def != null:
			result[def.id] = def
	return result
