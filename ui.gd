extends CanvasLayer

@onready var timer_label: Label = %Timer
@onready var extra_timer_label: Label = %ExtraTime
@onready var best_time_label: Label = %BestTime
@onready var checkpoint_label: Label = %Checkpoint

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
