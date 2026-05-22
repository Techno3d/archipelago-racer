extends CSGTorus3D # CHANGE THIS TO MESH INSTANCE


@export var times: Array[float] = [60]
var next_time: float = 900
var current_run_timer: float = 0

var started: bool = false

@export var num_checkpoints = 0
var checkpoints_passed = 0
 

var best_time: float = -1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect(passed)
	pass # Replace with function body.

func _process(delta: float) -> void:
	if started:
		current_run_timer += delta	
	print(current_run_timer)

func passed(body) -> void:
	if body is not CharacterBody3D: return
	if not started:
		started = true
		return
	if checkpoints_passed != num_checkpoints: return
	
	if best_time == -1:
		best_time = current_run_timer
	elif current_run_timer < best_time:
		best_time = current_run_timer	
	while current_run_timer < next_time:
		if times.size() == 0:
			break
		else: 
			next_time = times.pop_front()
	current_run_timer = 0
