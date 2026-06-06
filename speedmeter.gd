class_name Speedmeter
extends Panel

var car: VehicularCar
@onready var speed_label: Label = $SpeedLabel
@onready var green: Panel = $MarginContainer/Control/Green
@onready var red: Panel = $MarginContainer/Red

func _ready() -> void:
	car = get_tree().get_first_node_in_group("PlayerCar")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if car != null:
		show()
		var speed = (car.linear_velocity * car.global_basis.z).length()	
		speed_label.text = "%.2fs mph" % speed
		var fraction = speed / car.top_speed
		green.size.x = red.size.x * fraction
		green.size.y = red.size.y
	else:
		hide()
