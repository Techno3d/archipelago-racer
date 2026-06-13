extends Node3D

@onready var music_player: AudioStreamPlayer = $Music
var is_started := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta) -> void:
	if !is_started and Globals.goal.started:
		is_started = Globals.goal.started
		music_player.play()
