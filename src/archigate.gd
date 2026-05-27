extends MeshInstance3D

@export var island: int

@export var gate_num: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect()


func _entered(body: Node3D):
	if body is PlayerCar:
		pass
