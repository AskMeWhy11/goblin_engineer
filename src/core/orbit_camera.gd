class_name OrbitCamera
extends Camera3D
## Orbit camera used by both build mode (fixed pivot) and simulation (follows a target).
## Middle mouse (or `extra_drag_button`) drag orbits, Shift+drag pans, wheel zooms.

var pivot := Vector3.ZERO
var target: Node3D
var yaw := 0.6
var pitch := -0.45
var distance := 14.0
var min_distance := 3.0
var max_distance := 80.0
## WASD/QE orbit and zoom from the keyboard (build mode only: in sim keys belong to the machine).
var key_orbit := false
var extra_drag_button := MOUSE_BUTTON_NONE


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(min_distance, distance * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(max_distance, distance * 1.1)
	elif event is InputEventMouseMotion:
		var dragging: bool = event.button_mask & MOUSE_BUTTON_MASK_MIDDLE != 0
		if extra_drag_button == MOUSE_BUTTON_RIGHT and event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0:
			dragging = true
		if not dragging:
			return
		if event.shift_pressed and target == null:
			var right := global_transform.basis.x
			var up := global_transform.basis.y
			pivot += (-right * event.relative.x + up * event.relative.y) * distance * 0.0015
		else:
			yaw -= event.relative.x * 0.006
			pitch = clampf(pitch - event.relative.y * 0.006, -1.5, 0.3)


func _process(delta: float) -> void:
	if not current:
		return
	if is_instance_valid(target):
		pivot = pivot.lerp(target.global_position, 1.0 - exp(-10.0 * delta))
	if key_orbit:
		var turn := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		var tilt := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		var zoom := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
		yaw += turn * delta * 1.8
		pitch = clampf(pitch + tilt * delta * 1.2, -1.5, 0.3)
		distance = clampf(distance * (1.0 + zoom * delta), min_distance, max_distance)
	update_transform()


func update_transform() -> void:
	var offset := Basis.from_euler(Vector3(pitch, yaw, 0.0)) * Vector3(0, 0, distance)
	global_position = pivot + offset
	look_at(pivot, Vector3.UP)
