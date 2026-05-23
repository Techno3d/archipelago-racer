extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect(passed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func passed(body) -> void:
	if body is not CharacterBody3D: return
	Globals.checkpoint_passed.emit()
