extends CharacterBody3D

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

	var tb: TerraBrush = get_node_or_null("../TerraBrush")
	
	if tb:
		interact_terrain(tb)
	
	
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

# handles interaction points and respawning
func interact_terrain(tb: TerraBrush):
	if is_on_floor() and get_last_slide_collision() != null:
			
			# Get the current collision
			var collision = get_last_slide_collision()

			# Let's make sure the collider is the collider of the Terrain
			if collision.get_collider() == tb.getTerrainCollider():

				# The variable playerX and playerZ are the variables for the global position of the player
				var result = tb.getPositionInformation(global_position.x, global_position.z)
				tb.addInteractionPoint(global_position.x,global_position.z)
				# If we don't get a res*ult, it means we are out of the terrain
				if result != null:
					# The texture at position 0 is the most present one
					var _mainTexture = result.get_textures()[0].get_name() if result.get_textures().size() > 0 else ""

					if result.get_waterDeepness() > 1.2:
						respawn()
						print("respawning!")

			

func respawn():
	pass
