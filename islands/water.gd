extends MeshInstance3D

@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	area_3d.body_entered.connect(body_entered)

# Called when the node enters the scene tree for the first time.
func body_entered(body: Node3D):
	if body is VehicularCar:
		(body as VehicularCar).respawn()
