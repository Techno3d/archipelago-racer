extends MeshInstance3D

@onready var collider: Area3D = $Area3D
@export var boost_mult: float = 40
@export var boost_time: float = 1

func _ready() -> void:
	collider.body_entered.connect(boost_car)

func boost_car(body: Node3D):
	if body is not VehicularCar: return
	var car := body as VehicularCar
	car.apply_central_impulse(car.mass * boost_mult * boost_time * global_basis.z)
