extends PanelContainer

@export_file_path("*.tscn") var islands: Array[String]
@export var buttons: Array[Button]
const PASS_ID_TO_BUTTON_INDEX: Dictionary[int,int] = {
	1:0,
	2:4,
	3:3,
	4:2,
	5:1
}
	#"Volcano Pass": 1, # I want to implement random starting island, but for now we will not use volcano pass
	#"Mountain Pass": 2,
	#"Desert Pass": 3,
	#"Lake Pass": 4,
	#"Forest Pass": 5,
	#"Hype": 6
#}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("a")
	for i: int in range(len(buttons)):
		print("c")
		var button: Button = buttons[i]
		button.pressed.connect(load_scene.bind(i))
		# On archipelago connection, enable/disable buttons
	if Archipelago.conn:
		print("b")
		archi_setup()
	Archipelago.connected.connect(func(conn: ConnectionInfo, json: Dictionary): 
		print("3")
		archi_setup()
		)

func load_scene(ind: int):
	get_tree().change_scene_to_file(islands[ind])

func archi_setup():
	print("d")
	if not Archipelago.conn:
		return
	for button: Button in buttons:
		button.disabled = true
	for item: NetworkItem in Archipelago.conn.received_items:
		if PASS_ID_TO_BUTTON_INDEX.has(item.id):
			buttons[PASS_ID_TO_BUTTON_INDEX[item.id]].disabled = false
	buttons[0].disabled = false # override to figure out stretch goal
	
