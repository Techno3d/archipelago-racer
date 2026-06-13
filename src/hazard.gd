extends Area3D

@export_multiline() var death_reason: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_body_entered)

func _input(event: InputEvent) -> void:
	if OS.has_feature("debug"):
		if event is InputEventKey and(event as InputEventKey).keycode == KEY_P:
			if Archipelago.conn and Archipelago.is_deathlink():
				print(death_reason)
				Archipelago.conn.send_deathlink(death_reason)
		
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _body_entered(body:Node3D):
	if body is VehicularCar:
		if Archipelago.conn and Archipelago.is_deathlink():
			print(death_reason)
			Archipelago.conn.send_deathlink(death_reason)
		(body as VehicularCar).respawn()
