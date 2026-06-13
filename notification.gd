extends PanelContainer

var is_playing_notification: bool = false
var notification_queue: Array[String] = []
@export var notification_hang_time: float = 0.74
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

const showing_x: float = 970
@onready var notification_label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.send_notification.connect(_recieved_notification)

func _recieved_notification(to_show: String):
	notification_queue.push_back(to_show)
	
	if is_playing_notification: return
	is_playing_notification = true
	
	while notification_queue.size() > 0:
		await play_notification_anim(notification_queue.pop_front())
	
	is_playing_notification = false

	
func play_notification_anim(to_show):
	notification_label.text = to_show
	animation_player.play("show_notification")
	await animation_player.animation_finished
	
	await get_tree().create_timer(notification_hang_time).timeout
	
	animation_player.play_backwards("show_notification")
	await animation_player.animation_finished
	notification_label.text = ""
