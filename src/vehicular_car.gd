extends RigidBody3D


var turn_speed = 1
var current_turn = 0.0
var turn_friction = 4.0  
var turn_angle = 45
var max_turn = 20
var last_ground_up: Vector3 = Vector3.UP

@export var accel_curve: Curve
@export var accel = 10.0
@export var top_speed: float = 35
@export var power_steering_factor: float = 2.1
@export var air_damp: float = 0.05
@onready var car_model: CarModel = $Car
@onready var wheel_base: Area3D = $base
@onready var steering_point: Node3D = $SteeringPoint

# Car Wheel Contact Points
@onready var fl_contact: Marker3D = $FLContact
@onready var rl_contact: Marker3D = $RLContact

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wheel_base.body_entered.connect(on_ground)
	wheel_base.body_exited.connect(on_ground)
	pass # Replace with function body.

func on_ground(_body: Node3D):
	if wheel_base.has_overlapping_bodies():
		linear_damp = 1
		gravity_scale = 3.0
	else:
		linear_damp = air_damp
		gravity_scale = 2.0
		last_ground_up = (global_basis*Vector3.UP).normalized()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var throttle = Input.get_action_strength("accel")
	var breaking = Input.get_action_strength("reverse")
	var turn_input = Input.get_axis("left", "right")
	car_model.steer = turn_input * turn_angle * TAU/180.
	# print("%.1f %.1f %.1f %.2f" % [throttle, breaking, turn_input, linear_velocity.length()])

	if not wheel_base.has_overlapping_bodies():
		# Air controls
		var up_axis = (global_basis*Vector3.UP).normalized()
		var air_factor = clampf(up_axis.dot(last_ground_up)-0.7, 0.05, 1)
		var pitch_input = throttle-breaking
		state.apply_torque((global_basis*Vector3.RIGHT).normalized()*air_factor*pitch_input*mass)
		state.apply_torque(up_axis*air_factor*turn_input*mass)
		return
	
	# Ground controls
	var forward_dir: Vector3 = (global_transform.basis * Vector3(0,0,1)).normalized()
	var turn_quat = Quaternion.from_euler(Vector3(0, turn_angle*turn_input, 0) * global_transform.basis).normalized()
	# var wheel_dir = forward_dir.rotated(global_transform.basis*Vector3.UP, -turn_angle*turn_input*accel_curve.sample(angular_velocity.length()/max_turn))
	var wheel_dir = forward_dir * turn_quat
	var perp_wheel_dir = wheel_dir.rotated(global_basis*Vector3.UP, -PI/2)
	# # # Mass times accel * direction of wheel * where on accel curve. Power of engine/motor is limited, but it takes more power the faster you are to move
	# # # as `P = F * v` I think. This also serves to clamp the speed
	# # # Factor of 100 is there to make it work, idk why it doesn't without it
	var motor_force = forward_dir * throttle * accel * mass * accel_curve.sample(clampf(linear_velocity.length()/top_speed, 0, 1)) * 100
	var breaking_force = -forward_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(linear_velocity.length()/(top_speed/2.), 0, 1)*-1) * 100

	# cross friction must be higher than in line
	var fraction_linear_cross_front = (perp_wheel_dir).dot(linear_velocity)
	var fraction_linear_cross_back = (global_basis*Vector3.RIGHT).dot(linear_velocity)
	var fraction_linear_cross = (fraction_linear_cross_back+3*fraction_linear_cross_front)/4.
	state.apply_central_force(perp_wheel_dir*fraction_linear_cross*-1*mass*0.9)


	state.apply_torque((global_basis*steering_point.position*clampf(linear_velocity.length()/(top_speed/3), 0, 1)).cross(wheel_dir*mass*0.6) * sign(linear_velocity.dot(wheel_dir)))

	# I originally split the motor force to do "power steering", where the front wheels rotate their force, but that gets jumpy
	var turn_quat_lower = Quaternion.from_euler(Vector3(0, turn_input * TAU/180.*power_steering_factor * accel_curve.sample(angular_velocity.length()/max_turn), 0) * global_transform.basis).normalized()
	state.apply_force(motor_force/4. * turn_quat_lower, global_basis*fl_contact.position)
	state.apply_force(motor_force/4. * turn_quat_lower, global_basis*(fl_contact.position*Vector3(-1,1,1)))
	state.apply_force(motor_force/4., global_basis*rl_contact.position)
	state.apply_force(motor_force/4., global_basis*(rl_contact.position*Vector3(-1,1,1)))
	# state.apply_central_force(motor_force)
	state.apply_force(breaking_force/4. * turn_quat_lower, global_basis*fl_contact.position)
	state.apply_force(breaking_force/4. * turn_quat_lower, global_basis*(fl_contact.position*Vector3(-1,1,1)))
	state.apply_force(breaking_force/4., global_basis*rl_contact.position)
	state.apply_force(breaking_force/4., global_basis*(rl_contact.position*Vector3(-1,1,1)))
	# state.apply_central_force(breaking_force)

func _process(_delta: float) -> void:
	car_model.speed = linear_velocity.length()
