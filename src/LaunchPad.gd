extends MeshInstance3D
class_name Launchpad

var enabled: bool = false
var id: int = -1

@onready var area_3d: Area3D = $Area3D

var active: bool = false
var world: Node
var car: VehicularCar

@export var island: String

# Path to follow. Should be a child of a Path3D node
@export var path: PathFollow3D

# Speed to launch in percent of path per second.
@export var speed: float = 50

# Block when not active
@onready var static_body: StaticBody3D = $StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.loop = false
	area_3d.body_entered.connect(body_entered)
	if Globals.are_pads_activated.get(island.to_lower()): 
		$StaticBody3D.queue_free()
		
	
	if active:
		static_body.process_mode = Node.PROCESS_MODE_DISABLED
		static_body.hide()
	else:
		static_body.process_mode = Node.PROCESS_MODE_ALWAYS
		static_body.show()

func _physics_process(delta: float) -> void:
	if active:
		car.global_position = path.global_position
		path.progress_ratio += speed/100 * delta
	
	
	if path.progress_ratio >= 1 and active:
		active = false
		car.freeze = false
		car.linear_velocity = -car.global_basis.y * 3

	
		


func body_entered(body: Node3D) -> void:
	if not Globals.are_pads_activated.get(island.to_lower()): return
	if body is not VehicularCar: return
	world = body.get_parent()
	car = body
	car.freeze = true
	active = true
	path.progress_ratio = 0
	car.global_position = global_position
