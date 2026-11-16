class_name WoodTag
extends Control
## A parchment tag hung crookedly on one nail: the heading of a wooden panel.

const PAPER := Color("ead9b0")
const INK := Color("3a2414")
const OUTLINE := Color("2e1c10")
const NAIL := Color("7d8990")

var text := "":
	set(value):
		text = value
		update_minimum_size()
		queue_redraw()
var font_size := 18
## Fixed per text, so a tag does not wobble between redraws.
var tilt_degrees := 3.0


func _init(tag_text := "", size := 18) -> void:
	font_size = size
	text = tag_text
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var roll := absi(hash(tag_text)) % 7  # 0..6
	tilt_degrees = (roll - 3) * 1.2
	if absf(tilt_degrees) < 1.0:
		tilt_degrees = 2.4


func _get_minimum_size() -> Vector2:
	var font := get_theme_default_font()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Vector2(text_size.x + 44.0, maxf(24.0, text_size.y + 10.0))


func _draw() -> void:
	var half := size / 2.0 - Vector2(3, 2)
	draw_set_transform(size / 2.0, deg_to_rad(tilt_degrees), Vector2.ONE)
	var paper := PackedVector2Array([
		Vector2(-half.x + 8, -half.y), Vector2(half.x - 6, -half.y), Vector2(half.x, -1),
		Vector2(half.x - 8, half.y), Vector2(-half.x + 12, half.y), Vector2(-half.x + 6, half.y - 5),
		Vector2(-half.x, half.y - 3), Vector2(-half.x + 3, 0),
	])
	draw_colored_polygon(paper, PAPER)
	var outline := paper.duplicate()
	outline.append(paper[0])
	draw_polyline(outline, OUTLINE, 2.0, true)
	var font := get_theme_default_font()
	var ascent := font.get_ascent(font_size)
	var height := font.get_height(font_size)
	draw_string(font, Vector2(-half.x, -height / 2.0 + ascent), text, HORIZONTAL_ALIGNMENT_CENTER, half.x * 2.0, font_size, INK)
	draw_circle(Vector2(0, -half.y + 4), 3.6, OUTLINE)
	draw_circle(Vector2(0, -half.y + 4), 2.4, NAIL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
