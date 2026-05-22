extends CharacterBody3D


var SPEED = 0.0
var accel = 40.0
var friction = 1.0
var top_speed = 200

var turn_speed = 2.5
var current_turn = 0.0
var turn_friction = 4.0  
var max_turn = 1.0

func _physics_process(delta: float) -> void:
	print("SPEED: ", SPEED, " | velocity: ", velocity)
	
	
	if Input.is_action_pressed("accel"):
		SPEED = clamp(SPEED + accel * delta,0, top_speed)
	elif Input.is_action_pressed("reverse"):
		SPEED = clamp(SPEED - accel * delta,-top_speed * 0.5, 0)
	else:
		SPEED = move_toward(SPEED,0,friction)
		
	if not is_on_floor():
		velocity += get_gravity() * delta


	var turn_input = Input.get_axis("left", "right")
	current_turn = move_toward(current_turn, turn_input * max_turn, turn_friction * delta)

	var speed_factor = clamp(abs(SPEED) / top_speed, 0.0, 1.0)
	rotate_y(-current_turn * turn_speed * speed_factor * delta)
	
		
	velocity.x = -transform.basis.z.x * SPEED
	velocity.z = -transform.basis.z.z * SPEED
		

	move_and_slide()
