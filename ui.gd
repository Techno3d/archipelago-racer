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
@onready var medal_anim_texture: TextureRect = $HudMedalAnim/TextureRect
@onready var final_dest: Control = $HudMedalAnim/FinalDestination
@onready var best_time_medal: TextureRect = $MarginContainer/MainContainer/Top/TimeStuff/VBoxContainer2/Control/TextureRect
@onready var new_pb: NewRecord = $MarginContainer/NewRecord
var last_medal_idx: int = 5
var dir_medal_anim: Vector2
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
	medal_anim_texture.hide()
	medal_anim_texture.global_position = current_time_medal.global_position
	dir_medal_anim = final_dest.position - medal_anim_texture.position
	Globals.goal.new_personal_best.connect(new_pb.celebrate_record)
	Globals.goal.new_personal_best.connect(func(time: float):
		Globals.medal_img[Globals.goal.island_index] = set_medal_image(time)
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
	var medal_img_idx := set_medal_image(Globals.goal.current_run_timer + Globals.goal.penalty_timer)
	if last_medal_idx != medal_img_idx:
		medal_anim_texture.global_position = current_time_medal.global_position
		medal_anim_texture.texture = medal_imgs[last_medal_idx]
		medal_anim_texture.show()
		last_medal_idx = medal_img_idx
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(medal_anim_texture, "position:y", medal_anim_texture.position.y + dir_medal_anim.y, 0.8)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(medal_anim_texture, "position:x", medal_anim_texture.position.x + dir_medal_anim.x, 0.8)
		tween.tween_property(medal_anim_texture, "rotation", final_dest.rotation, 0.8)
		tween.tween_property(medal_anim_texture, "modulate:a", 0, 0.8)
		tween.finished.connect(func(): 
			medal_anim_texture.hide()
			medal_anim_texture.modulate.a = 1
		)

	current_time_medal.texture = medal_imgs[medal_img_idx]
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
