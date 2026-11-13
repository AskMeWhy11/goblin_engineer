extends TestCase


func test_all_24_bases_are_distinct_rotations() -> void:
	var seen := {}
	for i in Orientations.COUNT:
		var b := Orientations.basis(i)
		assert_almost(b.determinant(), 1.0, 0.001)
		seen[str(b.x.round()) + str(b.y.round())] = true
	assert_eq(seen.size(), 24)


func test_index_zero_is_identity() -> void:
	assert_true(Orientations.basis(0).is_equal_approx(Basis.IDENTITY))


func test_four_turns_return_to_start() -> void:
	for axis: Vector3i in [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]:
		var o := 0
		for _i in 4:
			o = Orientations.rotated(o, axis)
		assert_eq(o, 0)


func test_world_normal_follows_rotation() -> void:
	var o := Orientations.rotated(0, Vector3i.UP)
	var n := Orientations.world_normal(o, Vector3i.RIGHT)
	assert_eq(n.y, 0)
	assert_true(n != Vector3i.RIGHT)
	assert_eq(n.length_squared(), 1)
