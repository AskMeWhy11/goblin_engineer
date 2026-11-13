extends TestCase


func _piece() -> Destructible:
	var d := Destructible.new()
	d.freeze = true
	tree.root.add_child(d)
	d.global_position = Vector3(0, 3000, 0)
	d.remember_start()
	return d


func test_survives_below_toughness() -> void:
	var d := _piece()
	d.take_hit(299.0)
	assert_true(not d.is_destroyed)
	assert_true(not d.is_down())
	d.free()


func test_accumulates_hits() -> void:
	var d := _piece()
	d.take_hit(200.0)
	d.take_hit(200.0)
	assert_true(d.is_destroyed)
	assert_true(d.is_down())
	assert_true(not d.visible)
	d.free()


func test_knocked_far_from_its_place_counts_as_down() -> void:
	var d := _piece()
	d.global_position += Vector3(1.0, 0, 0)
	assert_true(not d.is_down(), "1 m is not enough")
	d.global_position += Vector3(1.0, 0, 0)
	assert_true(d.is_down())
	assert_true(not d.is_destroyed)
	d.free()


func test_reset_restores_everything() -> void:
	var d := _piece()
	d.take_hit(1000.0)
	d.global_position += Vector3(5, 0, 0)
	d.reset()
	assert_true(not d.is_destroyed)
	assert_true(not d.is_down())
	assert_true(d.visible)
	assert_true(d.global_position.is_equal_approx(Vector3(0, 3000, 0)))
	d.free()
