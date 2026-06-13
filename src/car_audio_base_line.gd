extends AudioStreamPlayer3D

@export var lower: float = 1.2
@export var higher: float = 1.6

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var throttle := Input.get_axis("reverse", "accel")
	var avg := (lower + higher) / 2.
	var diff := higher-lower
	pitch_scale = move_toward(pitch_scale, clampf(avg + diff*throttle, lower, higher), delta)
