extends AudioStreamPlayer

var ocean_audio: AudioStreamWAV = preload("res://assets/sfx_music/ocean-crete-2.wav")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    stream = ocean_audio
    get_tree().create_timer(randf_range(3, 10)).timeout.connect(random_sound)

func random_sound():
    if playing:
        stop()
    else:
        play()
    get_tree().create_timer(randf_range(8, 50)).timeout.connect(random_sound)