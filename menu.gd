extends PanelContainer

@export_file_path("*.tscn") var islands: Array[String]
@export var buttons: Array[Button]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i: int in range(len(buttons)):
		var button: Button = buttons[i]
		button.pressed.connect(load_scene.bind(i))
		


func load_scene(ind: int):
	get_tree().change_scene_to_file(islands[0])
