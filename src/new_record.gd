extends VBoxContainer
class_name NewRecord

@onready var main_label: Label = $NewRecordText
@onready var time_label: Label = $Time
var original_color: Color
var is_original := true

func _ready() -> void:
	original_color = main_label.modulate
	get_tree().create_timer(1).timeout.connect(swap_color)
	hide()

func celebrate_record(new_best: float) -> void:
	time_label.text = "%.2fs" % new_best
	show()
	await get_tree().create_timer(5).timeout
	hide()

func swap_color():
	is_original = !is_original
	if is_original:
		main_label.modulate = Color.LIGHT_GRAY 
	else:
		main_label.modulate = original_color
	get_tree().create_timer(0.5).timeout.connect(swap_color)
	