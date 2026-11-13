class_name Orientations
## The 24 axis-aligned rotations of a cube, addressed by index. Index 0 is identity.

const COUNT := 24
const _AXES: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3.LEFT, Vector3.DOWN, Vector3.FORWARD]

static var _bases: Array[Basis] = []


static func _table() -> Array[Basis]:
	if _bases.is_empty():
		_bases.append(Basis.IDENTITY)
		for x in _AXES:
			for y in _AXES:
				if absf(x.dot(y)) > 0.5:
					continue
				var b := Basis(x, y, x.cross(y))
				if not b.is_equal_approx(Basis.IDENTITY):
					_bases.append(b)
	return _bases


static func basis(index: int) -> Basis:
	return _table()[index]


## Rotates orientation `index` by 90 degrees around a world axis and returns the new index.
static func rotated(index: int, axis: Vector3i) -> int:
	var target := Basis(Vector3(axis), PI / 2.0) * basis(index)
	var table := _table()
	for i in COUNT:
		if table[i].is_equal_approx(target):
			return i
	return index


static func world_normal(index: int, local_normal: Vector3i) -> Vector3i:
	return Vector3i((basis(index) * Vector3(local_normal)).round())
