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
@export var accel = 0.25
@export var top_speed: float = 35
@export var power_steering_factor: float = 2.1
@export var air_damp: float = 0.05
@export var mu_k: float = 0.8
@export var mu_s: float = 0.9
@onready var car_model: CarModel = $Car
@onready var wheel_base: Area3D = $base
@onready var base2: Area3D = $base2
@onready var reset_collider: Area3D = $ResetCollider
@onready var steering_point: Node3D = $SteeringPoint
@onready var cam_pivot: Node3D = $CamPivot
@onready var downforce_cast: RayCast3D = $Downforce
@onready var restart_timer: Timer = $Timer

# Suspension
@export var spring_constant = 80000
@export_range(0, 3, .01) var damp_ratio = 0.9
var damp_constant
@export var rest_dist = 0.44
@onready var fl_raycast: RayCast3D = $FLRay
@onready var rl_raycast: RayCast3D = $RLRay
@onready var fr_raycast: RayCast3D = $FRRay
@onready var rr_raycast: RayCast3D = $RRRay
var raycasts: Array[RayCast3D]

# Car Wheel Contact Points
@onready var fl_contact: Marker3D = $FLContact
@onready var rl_contact: Marker3D = $RLContact
@onready var fr_contact: Marker3D = $FRContact
@onready var rr_contact: Marker3D = $RRContact

signal restart_hint()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wheel_base.body_entered.connect(on_ground)
	wheel_base.body_exited.connect(on_ground)
	damp_constant = 2*sqrt(spring_constant*mass)*damp_ratio/9
	raycasts = [fl_raycast, rl_raycast, fr_raycast, rr_raycast]
	spawn_point = transform
	reset_collider.body_entered.connect(func(_body: Node3D):
		if !wheel_base.has_overlapping_bodies() and !base2.has_overlapping_bodies() and reset_collider.has_overlapping_bodies():
			var timer: SceneTreeTimer = get_tree().create_timer(3)
			timer.timeout.connect(check_respawn)
	)
	restart_timer.timeout.connect(func(): restart_hint.emit())
	if Archipelago.conn:
		Archipelago.conn.deathlink.connect(respawn)

func on_ground(_body: Node3D):
	if wheel_base.has_overlapping_bodies() or base2.has_overlapping_bodies():
		linear_damp = 0.3
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

	if downforce_cast.is_colliding():
		state.apply_central_force(-global_basis.y * mass * 5)

	if !wheel_base.has_overlapping_bodies() and !base2.has_overlapping_bodies():
		# Air controls
		var up_axis = (global_basis*Vector3.UP).normalized()
		var air_factor = clampf(up_axis.dot(last_ground_up)-0.6, 0.05, 1)
		var pitch_input = Input.get_axis("pitch_back", "pitch_forward")
		state.apply_torque((global_basis*Vector3.RIGHT).normalized()*air_factor*pitch_input*mass)
		state.apply_torque(up_axis*air_factor*-turn_input*mass)
		return

	# Suspension
	for raycast in raycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var contact = raycast.get_collision_point()
			var spring_len = raycast.global_position.distance_to(contact)
			# (raycast.get_child(0) as Marker3D).position.y = -spring_len
			var spring_up = raycast.global_basis.y
			# The x in F=-kx
			var offset = rest_dist - spring_len
			var point_vel = state.linear_velocity + state.angular_velocity.cross(contact - global_position)
			# var damped_spring_force = (offset*spring_constant - damp_constant*(state.get_velocity_at_local_position(raycast.position).dot(spring_up)))*raycast.get_collision_normal()
			var damped_spring_force = (offset*spring_constant - damp_constant*(point_vel.dot(spring_up)))*raycast.get_collision_normal()
			state.apply_force(damped_spring_force, contact - global_position)

	var speed = (state.linear_velocity * global_basis.z).length()
	
	# Ground controls
	var forward_dir: Vector3 = (global_transform.basis * Vector3(0,0,1)).normalized()
	var turn_quat = Quaternion.from_euler(Vector3.UP * turn_angle*turn_input).normalized()
	# var wheel_dir = forward_dir.rotated(global_transform.basis*Vector3.UP, -turn_angle*turn_input*accel_curve.sample(angular_velocity.length()/top_angular_speed))
	var wheel_dir = (global_transform.basis * (Vector3(0,0,1) * turn_quat)).normalized() 
	var perp_wheel_dir = wheel_dir.rotated(global_basis*Vector3.UP, -PI/2)

	# cross friction must be higher than in line
	# Max static friction is mu_s * N, and N should be mass times tPlayerhe sign of the angle between gravity and up for car
	var max_static_friction = abs(mass*mu_s*(global_basis*Vector3.DOWN).normalized().dot(get_gravity()*gravity_scale))
	var global_down = (global_basis*Vector3.DOWN).normalized()
	var global_right = (global_basis*Vector3.RIGHT).normalized()
	var up_ramp = get_gravity().cross(global_down).cross(global_down).normalized()
	# Cross product here is for sin(theta)
	var tangential_gravity = abs((mass * get_gravity().cross(global_down).length() * -up_ramp).dot(global_right))
	if (tangential_gravity) < max_static_friction:
		# Static Friction
		state.apply_central_force(up_ramp*tangential_gravity)
	# Technically kinetic should only be if no static, but I don't wanna calculate static friction with velocity, I just wanna cancel gravity
	# Kinetic Friction
	var fraction_linear_cross_front = perp_wheel_dir.dot(state.linear_velocity)
	var fraction_linear_cross_back = global_basis.x.dot(state.linear_velocity)
	state.apply_central_force(perp_wheel_dir*fraction_linear_cross_front*-1*mass*mu_k * 1.2)
	state.apply_central_force(global_basis.x*fraction_linear_cross_back*-1*mass*mu_k * 1.5)


	# Torque should be r x F, where r is the position offset from CM to force, and F is the force.
	var steer_dir = (steering_point.global_position - global_position).normalized().cross(wheel_dir)
	# Not physics based turning force magnitude
	var steer_torque = steer_dir * mass * 2 * turn_curve.sample(speed/top_speed) * sign(linear_velocity.dot(global_basis.z))
	state.apply_torque(steer_torque)

	# Mass times accel * direction of wheel * where on accel curve. Power of engine/motor is limited, but it takes more power the faster you are to move
	# as `P = F * v` I think. This also serves to clamp the speed
	# Factor of 100 is there to make it work, idk why it doesn't without it
	var motor_force = forward_dir * throttle * accel * mass * accel_curve.sample(clampf(speed/top_speed, 0, 1)) * 100
	var breaking_force = -forward_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(speed/(top_speed/2.), 0, 1)*-1) * 100

	var turn_quat_lower = Quaternion.from_euler(Vector3.UP * turn_input * TAU/180.*power_steering_factor * turn_curve.sample(state.angular_velocity.length()/top_angular_speed * speed/top_speed)).normalized()
	var less_wheel_dir = ((global_transform.basis * (Vector3(0,0,1) * turn_quat_lower)).normalized())
	var motor_force_steer = less_wheel_dir * throttle * accel * mass * accel_curve.sample(clampf(speed/top_speed, 0, 1)) * 100
	var breaking_force_steer = -less_wheel_dir * breaking * accel/2. * mass * accel_curve.sample(clampf(speed/(top_speed/2.), 0, 1)*-1) * 100

	# Using the actual turn on the front wheel cars usually ends in weird jumping behavior
	# Most of the torque should already be calculated above, this is just for extra turn
	state.apply_force(motor_force_steer/4., global_basis*fl_contact.position)
	state.apply_force(motor_force_steer/4., global_basis*fr_contact.position)
	state.apply_force(motor_force/4., global_basis*rl_contact.position)
	state.apply_force(motor_force/4., global_basis*rr_contact.position)
	state.apply_force(breaking_force_steer/4., global_basis*fl_contact.position)
	state.apply_force(breaking_force_steer/4., global_basis*fr_contact.position)
	state.apply_force(breaking_force/4., global_basis*rl_contact.position)
	state.apply_force(breaking_force/4., global_basis*rr_contact.position)

func _process(delta: float) -> void:
	car_model.speed = linear_velocity.length()
	if base2.has_overlapping_bodies() and not wheel_base.has_overlapping_bodies() and Globals.goal.started:
		Globals.goal.penalty_timer += delta
		if restart_timer.is_stopped():
			restart_timer.paused = false
			restart_timer.start(3)
	else:
		if !restart_timer.is_stopped():
			restart_timer.stop()
	if Input.is_action_just_released("reset") and Globals.goal.started:
		freeze = true
		var last := Globals.goal.last_checkpoint
		linear_velocity = Vector3.ZERO
		for child in get_parent().get_children():
			if last == 0:
				if child is TimeTrials:
					global_position = (child as Node3D).global_position + (child as Node3D).global_basis.x * 0.5 + (child as Node3D).global_basis.y * 0.3
					rotation = (child as Node3D).rotation + Vector3.UP * PI
			elif child is Checkpoint and (child as Checkpoint).id == last:
				global_position = (child as Node3D).global_position + (child as Node3D).global_basis.x * 0.5 + (child as Node3D).global_basis.y * 0.3
				rotation = (child as Node3D).rotation + Vector3.UP * PI
		freeze = false

func check_respawn():
	if !wheel_base.has_overlapping_bodies() and !base2.has_overlapping_bodies() and reset_collider.has_overlapping_bodies():
		Archipelago.conn.send_deathlink("did a turtle cosplay.")
		respawn()

func respawn():
	Globals.goal.reset()
	transform = spawn_point
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
