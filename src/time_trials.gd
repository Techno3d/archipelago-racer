extends MeshInstance3D 
class_name TimeTrials

@export var times: Array[float] = [60]
var next_time: float = 900
var current_run_timer: float = 0

var started: bool = false

@export var num_checkpoints = 0
var last_checkpoint: int = -1
 
var best_time: float = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect(passed)
	Globals.checkpoint_passed.connect(func(id: int): 
		if id - last_checkpoint <= 2:
			last_checkpoint = id
		)
	Globals.goal = self

func _process(delta: float) -> void:
	if started:
		current_run_timer += delta	
	print(current_run_timer)

func passed(body) -> void:
	if body is not VehicularCar: return
	if not started:
		started = true
		return
	if last_checkpoint < num_checkpoints-2: return
	
	if best_time == -1:
		best_time = current_run_timer
	elif current_run_timer < best_time:
		best_time = current_run_timer	
		
	while current_run_timer < next_time:
		if times.size() == 0:
			break
		else: 
			next_time = times.pop_front()
	
	reset()
	
func reset() -> void:
	current_run_timer = 0
	last_checkpoint = -1
	started = false
	
