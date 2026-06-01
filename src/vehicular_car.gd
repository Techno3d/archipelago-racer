extends RigidBody3D
class_name VehicularCar


var turn_speed = 1
var current_turn = 0.0
var turn_friction = 4.0  
var turn_angle = 45
var top_angular_speed = 20
var last_ground_up: Vector3 = Vector3.UP
var spawn_point: Transform3D

@export var accel_curve: Curve
@export var turn_curve: Curve
@export var accel = 10.0
@export var top_speed: float = 35
@export var power_steering_factor: float = 2.1
@export var air_damp: float = 0.05
@export var mu_k: float = 0.7
@export var mu_s: float = 0.9
@onready var car_model: CarModel = $Car
@onready var wheel_base: Area3D = $base
@onready var steering_point: Node3D = $SteeringPoint
@onready var cam_pivot: Node3D = $CamPivot
@onready var cam_point: Marker3D = $CamPoint

# Car Wheel Contact Points
@onready var fl_contact: Marker3D = $FLContact
@onready var rl_contact: Marker3D = $RLContact

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wheel_base.body_entered.connect(on_ground)
	wheel_base.body_exited.connect(on_ground)
	spawn_point = transform
	if Archipelago.conn:
		Archipelago.conn.deathlink.connect(respawn)

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
		var air_factor = clampf(up_axis.dot(last_ground_up)-0.6, 0.05, 1)
		var pitch_input = Input.get_axis("pitch_back", "pitch_forward")
		state.apply_torque((global_basis*Vector3.RIGHT).normalized()*air_factor*pitch_input*mass)
		state.apply_torque(up_axis*air_factor*-turn_input*mass)
		return
	
	# Ground controls
	var forward_dir: Vector3 = (global_transform.basis * Vector3(0,0,1)).normalized()
	var turn_quat = Quaternion.from_euler(Vector3.UP * turn_angle*turn_input).normalized()
	# var wheel_dir = forward_dir.rotated(global_transform.basis*Vector3.UP, -turn_angle*turn_input*accel_curve.sample(angular_velocity.length()/top_angular_speed))
	var wheel_dir = (global_transform.basis * (Vector3(0,0,1) * turn_quat)).normalized() 
	var perp_wheel_dir = wheel_dir.rotated(global_basis*Vector3.UP, -PI/2)

	# cross friction must be higher than in line
	# Max static friction is mu_s * N, and N should be mass times the sign of the angle between gravity and up for car
	var max_static_friction = abs(mass*mu_s*(global_basis*Vector3.DOWN).normalized().dot(get_gravity()*gravity_scale))
	var global_down = (global_basis*Vector3.DOWN).normalized()
	var global_right = (global_basis*Vector3.RIGHT).normalized()
	var up_ramp = get_gravity().cross(global_down).cross(global_down).normalized()
	# Cross product here is for sin(theta)
	var tangential_gravity = abs((mass * get_gravity().cross(global_down).length() * -up_ramp).dot(global_right))
	var fudge_factor = (state.linear_velocity*Vector3(1,0.1,1)).length()/top_speed*max_static_friction*1.036 + state.angular_velocity.length()/top_angular_speed*max_static_friction*1.04
	if (tangential_gravity + fudge_factor) < max_static_friction:
		# Static Friction
		state.apply_central_force(up_ramp*tangential_gravity)
	else:
		# Kinetic Friction
		var fraction_linear_cross_front = (perp_wheel_dir).dot(linear_velocity)
		var fraction_linear_cross_back = (global_basis*Vector3.RIGHT).dot(linear_velocity)
		state.apply_central_force(perp_wheel_dir*fraction_linear_cross_front*-1*mass*mu_k)
		state.apply_central_force((global_basis*Vector3.RIGHT)*fraction_linear_cross_back*-1*mass*mu_k)


	# Torque should be r x F, where r is the position offset from CM to force, and F is the force.
	var steer_dir = (steering_point.global_position - global_position).normalized().cross(wheel_dir)
	# Not physics based turning force magnitude
	var steer_torque = steer_dir * mass * 4 * clampf(linear_velocity.length()/(top_speed/3), 0, 1) * signf(linear_velocity.dot(wheel_dir))
	state.apply_torque(steer_torque)

	# Mass times accel * direction of wheel * where on accel curve. Power of engine/motor is limited, but it takes more power the faster you are to move
	# as `P = F * v` I think. This also serves to clamp the speed
	# Factor of 100 is there to make it work, idk why it doesn't without it
	var motor_force = forward_dir * throttle * accel * mass * accel_curve.sample(clampf(linear_velocity.length()/top_speed, 0, 1)) * 100
	var breaking_force = -forward_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(linear_velocity.length()/(top_speed/2.), 0, 1)*-1) * 100

	var turn_quat_lower = Quaternion.from_euler(Vector3.UP * turn_input * TAU/180.*power_steering_factor * turn_curve.sample(angular_velocity.length()/top_angular_speed * linear_velocity.length()/top_speed)).normalized()
	var less_wheel_dir = ((global_transform.basis * (Vector3(0,0,1) * turn_quat_lower)).normalized())
	var motor_force_steer = less_wheel_dir * throttle * accel * mass * accel_curve.sample(clampf(linear_velocity.length()/top_speed, 0, 1)) * 100
	var breaking_force_steer = -less_wheel_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(linear_velocity.length()/(top_speed/2.), 0, 1)*-1) * 100

	# Using the actual turn on the front wheel cars usually ends in weird jumping behavior
	# Most of the torque should already be calculated above, this is just for extra turn
	state.apply_force(motor_force_steer/4., global_basis*fl_contact.position)
	state.apply_force(motor_force_steer/4., global_basis*(fl_contact.position*Vector3(-1,1,1)))
	state.apply_force(motor_force/4., global_basis*rl_contact.position)
	state.apply_force(motor_force/4., global_basis*(rl_contact.position*Vector3(-1,1,1)))
	state.apply_force(breaking_force_steer/4., global_basis*fl_contact.position)
	state.apply_force(breaking_force_steer/4., global_basis*(fl_contact.position*Vector3(-1,1,1)))
	state.apply_force(breaking_force/4., global_basis*rl_contact.position)
	state.apply_force(breaking_force/4., global_basis*(rl_contact.position*Vector3(-1,1,1)))

func _process(_delta: float) -> void:
	car_model.speed = linear_velocity.length()

func respawn():
	Globals.goal.reset()
	transform = spawn_point
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
