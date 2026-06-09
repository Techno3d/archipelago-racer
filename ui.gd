extends CanvasLayer

@onready var timer_label: Label = %Timer
@onready var extra_timer_label: Label = %ExtraTime
@onready var best_time_label: Label = %BestTime
@onready var checkpoint_label: Label = %Checkpoint
@onready var restart_label: Label = $MarginContainer/MainContainer/Bottom/Restart
@onready var pause_container: MarginContainer = $MarginContainer/PauseContainer
@onready var main_menu: Button = %MainMenu
@onready var quit: Button = %Quit
var car: VehicularCar
@onready var current_time_medal: TextureRect = $MarginContainer/MainContainer/Top/TimeStuff/VBoxContainer/Control/TextureRect
@onready var best_time_medal: TextureRect = $MarginContainer/MainContainer/Top/TimeStuff/VBoxContainer2/Control/TextureRect
var main_menu_scene: PackedScene = preload("res://menu.tscn")
@export var medal_imgs: Array[Texture]

func _ready() -> void:
	restart_label.hide()
	pause_container.hide()
	car = get_tree().get_first_node_in_group("PlayerCar")
	if car != null:
		car.restart_hint.connect(func():
			restart_label.show()
			await get_tree().create_timer(4).timeout
			restart_label.hide()
		)
	main_menu.pressed.connect(func(): 
		get_tree().paused = false
		get_tree().change_scene_to_packed(main_menu_scene)
	)
	quit.pressed.connect(func():
		get_tree().quit()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		if !get_tree().paused:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			pause_container.show()
		else:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			pause_container.hide()

func _process(_delta: float) -> void:
	timer_label.text = "%.2fs" % [Globals.goal.current_run_timer]
	current_time_medal.texture = medal_imgs[set_medal_image(Globals.goal.current_run_timer)]
	if Globals.goal.penalty_timer > 0:
		extra_timer_label.text = "(+%.2fs)" % Globals.goal.penalty_timer
	else:
		extra_timer_label.text = ""
	if Globals.goal.best_time >= 0:
		best_time_label.text = "Personal Best: %.2fs" % Globals.goal.best_time
		best_time_medal.texture = medal_imgs[set_medal_image(Globals.goal.best_time)]
	else:
		best_time_label.text = ""
	checkpoint_label.text = "%d / %d" % [Globals.goal.last_checkpoint, Globals.goal.num_checkpoints]


func set_medal_image(time: float) -> int:
	
	var medal_index := -1
	for i in Globals.goal.ref_times.size():
		if time <= Globals.goal.ref_times[i]:
			medal_index = i  
	if time == 0.00 or time > Globals.goal.ref_times[0]:
		medal_index =5
	current_time_medal.texture = medal_imgs[medal_index] if medal_index >= 0 else null
	return medal_index
