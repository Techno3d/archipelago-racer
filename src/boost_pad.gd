extends MeshInstance3D

@onready var collider: Area3D = $Area3D
@export var boost_mult: float = 200
@export var island: String = ""

func _ready() -> void:
	(material_override as ShaderMaterial).set_shader_parameter("activated", Globals.are_pads_activated.get(island.to_lower()))

func _physics_process(_delta: float) -> void:
	if Globals.are_pads_activated.get(island.to_lower()) and collider.has_overlapping_bodies():
		for body in collider.get_overlapping_bodies():
			if body is VehicularCar:
				var car := body as VehicularCar
				car.apply_central_force(car.mass * boost_mult * global_basis.z)
				car.top_speed += 5
				get_tree().create_timer(2).timeout.connect(func(): car.top_speed -= 5)
