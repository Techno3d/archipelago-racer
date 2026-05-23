extends CharacterBody3D
class_name PlayerCar

var SPEED = 0.0
var accel = 20.0
var friction = 15.0
var top_speed = 40

var turn_speed = 1
var current_turn = 0.0
var turn_friction = 4.0  
var max_turn = 1.5

@export var accel_curve: Curve
@onready var car_model: CarModel = $CarMesh

func _ready() -> void:
	if Archipelago.conn:
		Archipelago.conn.deathlink.connect(respawn)

func _physics_process(delta: float) -> void:
	#print("SPEED: ", SPEED, " | velocity: ", velocity)
	car_model.speed = SPEED

	
	
	
	var throttle = Input.get_axis("reverse", "accel");
	if throttle == 0:
		SPEED = move_toward(SPEED,0,friction)
	else:
		SPEED = clampf(SPEED + throttle * accel * accel_curve.sample(SPEED/top_speed) * delta, -top_speed/2., top_speed)

	


	var turn_input = Input.get_axis("left", "right")
	current_turn = move_toward(current_turn, turn_input * max_turn, turn_friction * delta)
	car_model.steer = turn_input * max_turn

	var speed_factor = clamp(SPEED / top_speed, -0.5, 1.0)
	rotate_y(-current_turn * turn_speed * speed_factor * delta)
	
		
	velocity.x = -transform.basis.z.x * SPEED
	velocity.z = -transform.basis.z.z * SPEED
		
	if not is_on_floor():
		velocity += get_gravity() * delta * 2

	move_and_slide()

func respawn():
	print("put respawn code here")
