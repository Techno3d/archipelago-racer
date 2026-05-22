class_name CarModel 
extends MeshInstance3D

var speed: float = 0
var steer: float = PI
@onready var rears = $'Scene Collection/Car/WheelCollection/FRWheel'
@onready var forewards = $'Scene Collection/Car/WheelCollection/FLWheel'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rears.rotate_x(speed * delta)
	forewards.rotate_x(speed * delta)
	