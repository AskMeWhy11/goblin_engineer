extends PartBody
## The whistle: heavy, expensive, useless and very explosive. A place to park risk, or a projectile.

var silent := false


func apply_malfunction() -> void:
	silent = true


func malfunction_text() -> String:
	return "замолкла"
