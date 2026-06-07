extends CanvasLayer

@onready var timer_label: Label = %Timer
@onready var extra_timer_label: Label = %ExtraTime
@onready var best_time_label: Label = %BestTime
@onready var checkpoint_label: Label = %Checkpoint
@onready var restart_label: Label = $MarginContainer/MainContainer/Bottom/Restart
@onready var pause_container: MarginContainer = $MarginContainer/PauseContainer
var car: VehicularCar

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		if !get_tree().paused:
			get_tree().paused = true
			pause_container.show()
		else:
			get_tree().paused = false
			pause_container.hide()

func _process(_delta: float) -> void:
	timer_label.text = "%.2fs" % [Globals.goal.current_run_timer]
	if Globals.goal.penalty_timer > 0:
		extra_timer_label.text = "(+%.2fs)" % Globals.goal.penalty_timer
	else:
		extra_timer_label.text = ""
	if Globals.goal.best_time >= 0:
		best_time_label.text = "Personal Best: %.2fs" % Globals.goal.best_time
	else:
		best_time_label.text = ""
	checkpoint_label.text = "%d / %d" % [Globals.goal.last_checkpoint, Globals.goal.num_checkpoints]
