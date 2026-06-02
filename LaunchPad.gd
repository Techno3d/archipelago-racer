extends MeshInstance3D
class_name Launchpad

var enabled: bool = false
var id: int = -1

@onready var area_3d: Area3D = $Area3D

var active: bool = false
var world: Node
var car: VehicularCar


# Path to follow. Should be a child of a Path3D node
@export var path: PathFollow3D

# Speed to launch in percent of path per second.
@export var speed: float = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.loop = false
	area_3d.body_entered.connect(body_entered)
	
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	print(path.progress_ratio)
	if active:
		path.progress_ratio += speed/100 * delta
	
	
	if path.progress_ratio >= 1:
		car.reparent(world)
		active = false
		car.freeze = false
		
		


func body_entered(body: Node3D) -> void:
	if body is not VehicularCar: return
	world = body.get_parent()
	car = body
	car.freeze = true
	active = true
	path.progress_ratio = 0
	car.reparent(path)
	car.position = Vector3.ZERO
