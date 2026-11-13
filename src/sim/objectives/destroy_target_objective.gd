class_name DestroyTargetObjective
extends Objective
## Done when no more than `survivors_allowed` pieces under the level's "Target" node still stand.

@export var survivors_allowed := 3


func _pieces() -> Array[Destructible]:
	var result: Array[Destructible] = []
	var target := get_parent().get_node_or_null("Target")
	if target != null:
		for child in target.get_children():
			if child is Destructible:
				result.append(child)
	return result


func _check() -> bool:
	var pieces := _pieces()
	if pieces.is_empty():
		return false
	var standing := 0
	for piece in pieces:
		if not piece.is_down():
			standing += 1
	return standing <= survivors_allowed


func _on_reset() -> void:
	for piece in _pieces():
		piece.reset()
