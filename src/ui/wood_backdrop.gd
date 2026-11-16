class_name WoodBackdrop
extends Control
## A panel background nailed together from mismatched, crooked planks, with cracks, nails,
## tin patches and a rope. Everything is drawn from a seed, so a panel always looks the same.

const PLANKS: Array[Color] = [Color("5a3a22"), Color("6b4528"), Color("4e321d")]
const WALL_PLANKS: Array[Color] = [Color("3a2616"), Color("44301c"), Color("31200f")]
const OUTLINE := Color("2e1c10")
const NAIL := Color("c9b08a")
const TIN := Color("7d8990")
const ROPE_LIGHT := Color("c9a86a")
const ROPE_DARK := Color("a88a52")

var seed_value := 1
## Dark, wide planks for full-screen menu walls; no patches or rope.
var wall := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(queue_redraw)


## Plank outlines for a panel of `size`: vertical boards with uneven ends and seams.
static func layout(size: Vector2, seed: int, plank_width := 84.0) -> Array[PackedVector2Array]:
	var planks: Array[PackedVector2Array] = []
	if size.x <= 0.0 or size.y <= 0.0:
		return planks
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var count := maxi(1, roundi(size.x / plank_width))
	var width := size.x / count
	var top_x: Array[float] = []
	var bottom_x: Array[float] = []
	for i in count + 1:
		var wobble := 2.0 if i == 0 or i == count else 3.5
		top_x.append(i * width + rng.randf_range(-wobble, wobble))
		bottom_x.append(i * width + rng.randf_range(-wobble, wobble))
	for i in count:
		var top := rng.randf_range(-5.0, 3.0)
		var bottom := size.y + rng.randf_range(-3.0, 5.0)
		# Now and then a board is too short: sloppy carpentry.
		if count > 1 and rng.randf() < 0.22:
			bottom -= rng.randf_range(8.0, 16.0)
		planks.append(PackedVector2Array([
			Vector2(top_x[i], top),
			Vector2(top_x[i + 1], top + rng.randf_range(-3.0, 3.0)),
			Vector2(bottom_x[i + 1], bottom + rng.randf_range(-3.0, 3.0)),
			Vector2(bottom_x[i], bottom),
		]))
	return planks


func _draw() -> void:
	var planks := layout(size, seed_value, 150.0 if wall else 84.0)
	if planks.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1000
	var palette := WALL_PLANKS if wall else PLANKS
	for plank in planks:
		draw_colored_polygon(plank, palette[rng.randi() % palette.size()])
		var outline := plank.duplicate()
		outline.append(plank[0])
		draw_polyline(outline, OUTLINE, 2.5, true)
		_nail((plank[0] + plank[1]) / 2.0 + Vector2(rng.randf_range(-8, 8), 9))
		_nail((plank[2] + plank[3]) / 2.0 + Vector2(rng.randf_range(-8, 8), -9))
	for _i in (5 if wall else maxi(1, int(size.y / 130.0))):
		_crack(rng)
	if wall:
		return
	if size.x > 150.0 and size.y > 110.0:
		_patch(Vector2(rng.randf_range(16, 30), size.y - rng.randf_range(10, 20)), rng)
		if rng.randf() < 0.6:
			_patch(Vector2(size.x - rng.randf_range(14, 26), rng.randf_range(12, 22)), rng)
	if size.y > 230.0:
		_rope()


func _nail(at: Vector2) -> void:
	draw_circle(at, 3.6, OUTLINE)
	draw_circle(at, 2.4, NAIL)


func _crack(rng: RandomNumberGenerator) -> void:
	var point := Vector2(rng.randf_range(10, maxf(11, size.x - 10)), rng.randf_range(6, maxf(7, size.y - 40)))
	var line := PackedVector2Array([point])
	for _i in 3:
		point += Vector2(rng.randf_range(-7, 7), rng.randf_range(8, 15))
		line.append(point)
	draw_polyline(line, OUTLINE, 1.5, true)


## A crooked tin plate with a rivet in every corner.
func _patch(at: Vector2, rng: RandomNumberGenerator) -> void:
	var half := Vector2(rng.randf_range(15, 22), rng.randf_range(10, 14))
	draw_set_transform(at, deg_to_rad(rng.randf_range(-14, 14)), Vector2.ONE)
	draw_rect(Rect2(-half, half * 2.0), TIN)
	draw_rect(Rect2(-half, half * 2.0), OUTLINE, false, 2.0)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			draw_circle(Vector2(sx * (half.x - 4.5), sy * (half.y - 4.5)), 1.8, OUTLINE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Two strands of rope lashed down the left edge.
func _rope() -> void:
	for strand in 2:
		var line := PackedVector2Array()
		var x := 4.0 + strand * 6.0
		var steps := 12
		for i in steps + 1:
			var t := float(i) / steps
			line.append(Vector2(x + sin(t * 9.0 + strand) * 2.0, -8.0 + t * (size.y + 16.0)))
		draw_polyline(line, OUTLINE, 5.5 - strand, true)
		draw_polyline(line, ROPE_LIGHT if strand == 0 else ROPE_DARK, 3.5 - strand, true)
