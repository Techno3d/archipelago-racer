extends RigidBody3D


var turn_speed = 1
var current_turn = 0.0
var turn_friction = 4.0  
var turn_angle = 45
var max_turn = 15

@export var accel_curve: Curve
@export var accel = 10.0
@export var top_speed: float = 35
@onready var car_model: CarModel = $Car
@onready var wheel_base: Area3D = $base
@onready var steering_point: Node3D = $SteeringPoint

# Car Wheel Contact Points
@onready var fl_contact: Marker3D = $FLContact
@onready var fr_contact: Marker3D = $FRContact
@onready var rl_contact: Marker3D = $RLContact
@onready var rr_contact: Marker3D = $RRContact

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var throttle = Input.get_action_strength("accel")
	var breaking = Input.get_action_strength("reverse")
	var turn_input = Input.get_axis("left", "right")
	car_model.steer = turn_input * turn_angle * TAU/180.
	# print("%.1f %.1f %.1f %.2f" % [throttle, breaking, turn_input, linear_velocity.length()])

	if not wheel_base.has_overlapping_bodies():
		throttle = 0
		breaking = 0
		turn_input = 0
	var forward_dir: Vector3 = (global_transform.basis * Vector3(0,0,1)).normalized()
	# var turn_quat = Quaternion.from_euler(Vector3(0, turn_angle*turn_input*accel_curve.sample(angular_velocity.length()/max_turn), 0) * global_transform.basis).normalized()
	var wheel_dir = forward_dir.rotated(global_transform.basis*Vector3.UP, -turn_angle*turn_input*accel_curve.sample(angular_velocity.length()/max_turn))
	var perp_wheel_dir = wheel_dir.rotated(global_basis*Vector3.UP, -PI/2)
	# # # Mass times accel * direction of wheel * where on accel curve. Power of engine/motor is limited, but it takes more power the faster you are to move
	# # # as `P = F * v` I think. This also serves to clamp the speed
	# # # Factor of 100 is there to make it work, idk why it doesn't without it
	var motor_force = forward_dir * throttle * accel * mass * accel_curve.sample(clampf(linear_velocity.length()/top_speed, 0, 1)) * 100
	var breaking_force = -forward_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(linear_velocity.length()/(top_speed/2.), 0, 1)*-1) * 100

	# cross friction must be higher than in line
	var fraction_linear_cross = (perp_wheel_dir).dot(linear_velocity)
	state.apply_central_force(perp_wheel_dir*fraction_linear_cross*-1*mass*0.9)


	state.apply_torque((global_basis*steering_point.position*linear_velocity.length()/top_speed*2).cross(wheel_dir*mass*0.6))

	# state.apply_force(motor_force/8, fl_contact.global_position - global_position)
	# state.apply_force(motor_force/8., fr_contact.global_position - global_position)
	# state.apply_force(3*motor_force/8., rl_contact.global_position - global_position)
	# state.apply_force(3*motor_force/8., rr_contact.global_position - global_position)
	state.apply_central_force(motor_force)
	# state.apply_force(breaking_force/8. * turn_quat, fl_contact.global_position - global_position)
	# state.apply_force(breaking_force/8. * turn_quat, fr_contact.global_position - global_position)
	# state.apply_force(2*breaking_force/8., rl_contact.global_position - global_position)
	# state.apply_force(2*breaking_force/8., rr_contact.global_position - global_position)
	state.apply_central_force(breaking_force)

func _process(_delta: float) -> void:
	car_model.speed = linear_velocity.length()
