class_name PartTable
## The single source of part balance numbers. After editing, regenerate data/parts and scenes/parts:
##   powershell -File tools/generate_parts.ps1
##
## rates: failures per second at "Хлам" quality — x malfunction, y break, z explode.
## boom: [impulse N*s, radius m]. faces: local mount normals, [] = all six.
## base: local normal of the mount face (defaults to the only face when there is one).
## The look of each part is built in tools/part_models.gd; shape and size here are the physics shape.
## shape: box | sphere | cyl_x | cyl_y | cyl_z; size: box extents, or (radius, height, _) for cylinders.

## Quality tiers shared by every part except the core.
const TIERS := [
	{name = "Добротная", price = 1.0, rate = 0.04, margin = 8.0},
	{name = "Сойдёт", price = 0.6, rate = 0.3, margin = 3.0},
	{name = "Хлам", price = 0.3, rate = 1.0, margin = 0.8},
]

const A_NONE := 0
const A_HOLD := 1
const A_PRESS := 2

const PARTS := [
	{
		id = &"core", name = "Ядро", price = 0, mass = 20.0, rates = Vector3.ZERO, boom = [0.0, 0.0],
		activation = A_NONE, always_loaded = false, faces = [], removable = false, single_tier = true,
		shape = "box", size = Vector3(0.96, 0.96, 0.96), color = Color(0.35, 0.65, 0.25),
		script = "res://src/sim/parts/core.gd",
	},
	{
		id = &"block", name = "Блок", price = 10, mass = 5.0, rates = Vector3(0.015, 0.012, 0.0),
		boom = [0.0, 0.0], activation = A_NONE, always_loaded = true, faces = [],
		shape = "box", size = Vector3(0.96, 0.96, 0.96), color = Color(0.62, 0.45, 0.28),
		script = "res://src/sim/parts/block.gd",
	},
	{
		id = &"ballast", name = "Балласт", price = 15, mass = 40.0, rates = Vector3(0.0, 0.006, 0.0),
		boom = [0.0, 0.0], activation = A_NONE, always_loaded = true, faces = [],
		shape = "box", size = Vector3(0.96, 0.96, 0.96), color = Color(0.3, 0.3, 0.33),
		script = "res://src/sim/part_body.gd",
	},
	{
		id = &"free_wheel", name = "Колесо", price = 20, mass = 8.0, rates = Vector3(0.010, 0.010, 0.002),
		boom = [200.0, 2.0], activation = A_NONE, always_loaded = true, faces = [Vector3i.LEFT],
		shape = "cyl_x", size = Vector3(0.65, 0.3, 0.0), color = Color(0.55, 0.55, 0.55),
		script = "res://src/sim/parts/free_wheel.gd",
	},
	{
		id = &"motor_wheel", name = "Моторное колесо", price = 60, mass = 12.0,
		rates = Vector3(0.020, 0.010, 0.006), boom = [500.0, 3.0], activation = A_HOLD,
		always_loaded = false, faces = [Vector3i.LEFT], keys = [KEY_UP, KEY_DOWN],
		shape = "cyl_x", size = Vector3(0.65, 0.3, 0.0), color = Color(0.9, 0.55, 0.15),
		script = "res://src/sim/parts/motor_wheel.gd",
	},
	{
		id = &"steering_hinge", name = "Рулевой шарнир", price = 40, mass = 6.0,
		rates = Vector3(0.015, 0.010, 0.003), boom = [200.0, 2.0], activation = A_HOLD,
		always_loaded = false, faces = [], base = Vector3i.LEFT, keys = [KEY_RIGHT, KEY_LEFT],
		shape = "cyl_y", size = Vector3(0.4, 0.96, 0.0), color = Color(0.25, 0.5, 0.8),
		script = "res://src/sim/parts/steering_hinge.gd",
	},
	{
		id = &"rocket", name = "Ракета", price = 80, mass = 10.0, rates = Vector3(0.020, 0.010, 0.015),
		boom = [1200.0, 5.0], activation = A_HOLD, always_loaded = false, faces = [Vector3i.LEFT],
		keys = [KEY_SHIFT, KEY_NONE],
		shape = "cyl_z", size = Vector3(0.3, 0.96, 0.0), color = Color(0.85, 0.2, 0.2),
		marker = Vector3(0, 0, 0.5), script = "res://src/sim/parts/rocket.gd",
	},
	{
		id = &"cannon", name = "Пушка", price = 100, mass = 30.0, rates = Vector3(0.025, 0.008, 0.012),
		boom = [1200.0, 5.0], activation = A_PRESS, always_loaded = false, faces = [Vector3i.LEFT],
		keys = [KEY_C, KEY_NONE],
		shape = "cyl_z", size = Vector3(0.28, 0.96, 0.0), color = Color(0.2, 0.2, 0.22),
		marker = Vector3(0, 0, 0.5), script = "res://src/sim/parts/cannon.gd",
	},
	{
		id = &"powder_barrel", name = "Пороховая бочка", price = 50, mass = 15.0,
		rates = Vector3(0.010, 0.008, 0.020), boom = [2500.0, 7.0], activation = A_PRESS,
		always_loaded = true, faces = [], keys = [KEY_B, KEY_NONE],
		shape = "cyl_y", size = Vector3(0.42, 0.9, 0.0), color = Color(0.5, 0.12, 0.1),
		script = "res://src/sim/parts/powder_barrel.gd",
	},
	{
		id = &"whistle", name = "Свистелка", price = 120, mass = 60.0, rates = Vector3(0.015, 0.010, 0.040),
		boom = [2500.0, 7.0], activation = A_NONE, always_loaded = true, faces = [],
		shape = "sphere", size = Vector3(0.46, 0.0, 0.0), color = Color(0.6, 0.3, 0.75),
		script = "res://src/sim/parts/whistle.gd",
	},
]
