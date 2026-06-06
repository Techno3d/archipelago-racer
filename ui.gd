extends CanvasLayer

var goal: TimeTrials

const debug_text = "Checkpoints: {0}/{1} 
Current Time: {2} (+ {4})
Best Time: {3}"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Globals.goal: return
	$"VBoxContainer/HBoxContainer/Debug Label".text = debug_text.format(
		[Globals.goal.last_checkpoint+1,Globals.goal.num_checkpoints,"%0.2fs" % Globals.goal.current_run_timer,"%0.2fs" % Globals.goal.best_time, "%0.2fs" % Globals.goal.penalty_timer]
	)
