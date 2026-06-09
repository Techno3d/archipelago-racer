extends Node3D

@onready var cam_pivot: Node3D = get_parent()
@onready var car: VehicularCar = cam_pivot.get_parent()
@export var is_mouse_movement_enabled := false
@export var max_dist = 2
@export var max_angle_change: Vector2 = Vector2(10, 5)
var original_cam_pivot_polar: Vector3

func _ready() -> void:
	original_cam_pivot_polar = to_polar(cam_pivot.position)
	global_position = cam_pivot.global_position

func _physics_process(delta: float) -> void:
	var speed_factor := ((car.linear_velocity/car.top_speed).dot(car.global_basis.z) + 1)/2.
	global_position = global_position.move_toward(cam_pivot.global_position, ((cam_pivot.global_position-global_position).length() - max_dist * speed_factor)*delta*100)
	look_at(car.global_position)

## Returns a vector in the form of (r, theta, psi)
func to_polar(pos: Vector3) -> Vector3:
	var r = pos.length()
	return Vector3(r, atan2(pos.z,pos.x), acos(pos.y/pos.length()))

## Takes in a vector in the form of (r, theta, psi)
func to_cartesian(polar: Vector3) -> Vector3:
	var r = polar.x
	var theta = polar.y
	var psi = polar.z
	return Vector3(r*sin(psi)*cos(theta), r*cos(psi), r*sin(psi)*sin(theta))

func _input(event: InputEvent) -> void:
	print(is_mouse_movement_enabled)
	if event is InputEventMouseMotion && is_mouse_movement_enabled:
		var radian_max := max_angle_change * TAU/180
		var polar_cam := to_polar(cam_pivot.position)
		var motion_event := event as InputEventMouseMotion
		polar_cam.y += motion_event.screen_relative.x / 100
		polar_cam.y = clampf(polar_cam.y, original_cam_pivot_polar.y-radian_max.x, original_cam_pivot_polar.y+radian_max.x)
		polar_cam.z += motion_event.screen_relative.y / 100
		polar_cam.z = clampf(polar_cam.z, original_cam_pivot_polar.z-radian_max.y-10*TAU/180., original_cam_pivot_polar.z+radian_max.y)
		var new_cam_pos = to_cartesian(polar_cam)
		cam_pivot.position = new_cam_pos

func _process(delta: float) -> void:
	var polar_cam := to_polar(cam_pivot.position)
	polar_cam.y = move_toward(polar_cam.y, original_cam_pivot_polar.y, delta)
	polar_cam.z = move_toward(polar_cam.z, original_cam_pivot_polar.z, delta)
	var new_cam_pos = to_cartesian(polar_cam)
	cam_pivot.position = new_cam_pos
