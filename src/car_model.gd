class_name CarModel 
extends MeshInstance3D

var speed: float = 0
var steer: float = 0
var rotationx = 0
@onready var rears = $'RearWheel'
@onready var fl = $'FLWheel'
@onready var fr = $'FRWheel'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rears.rotate_x(speed * delta)
	rotationx += fmod(speed * delta, TAU) 
	fl.rotation = Vector3(rotationx,-steer*0.5,0)
	fr.rotation = Vector3(rotationx,-steer*0.5,0)

	
