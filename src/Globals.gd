extends Node

signal checkpoint_passed(id: int)

signal set_max_checkpoints(num: int)

signal send_notification(to_show: String)
var medal_tier = 2
var medals_required = 3
func _ready():
	if Archipelago.conn:
		_wire_ap(Archipelago.conn, {})
	Archipelago.connected.connect(_wire_ap)

func check_and_send_goal() -> bool:
	var count := 0
	for island_idx in range(5):
		var loc_id :int = island_idx * 5 + medal_tier
		if Archipelago.location_checked(loc_id):
			count += 1
		

	if count >= medals_required:
		Archipelago.set_client_status(Archipelago.ClientStatus.CLIENT_GOAL)
		return true
	return false

func _wire_ap(conn: ConnectionInfo, json: Dictionary):
	current_stat = 0
	print(json)
	var slot_data = json.get("slot_data")
	var death_link = 1.0 == slot_data.get("death_link")
	medal_tier =  int(slot_data.get("medal_tier_required"))
	medals_required = int(slot_data.get("islands_to_goal"))
	check_and_send_goal()
	Archipelago.set_deathlink(death_link) 
	conn.obtained_item.connect(_on_item_received)
	conn.refresh_items.connect(_on_items_refreshed)
	_on_items_refreshed(conn.received_items)
	
	

const BOOST_PAD_ITEMS := {
	"Launch and Boost Pads - Volcano": "volcano",
	"Launch and Boost Pads - Forest": "forest",
	"Launch and Boost Pads - Lake": "lake",
	"Launch and Boost Pads - Desert": "desert",
	"Launch and Boost Pads - Mountain": "mountain",
}
func _on_item_received(item: NetworkItem):
	var text =  Archipelago.conn.get_player_name(item.src_player_id)+ " sent you " + item.get_name()  
	send_notification.emit(text)
	_apply_item(item)

func _on_items_refreshed(items: Array[NetworkItem]):
	current_stat = 0
	for island in are_pads_activated.keys():
		are_pads_activated[island] = false
	for item in items:
		_apply_item(item)

func _apply_item(item: NetworkItem):
	var name := item.get_name()
	if name == "Progressive Stats Upgrade":
		current_stat = min(current_stat + 1, car_stats.size() - 1)
	elif name in BOOST_PAD_ITEMS:
		are_pads_activated[BOOST_PAD_ITEMS[name]] = true

var goal: TimeTrials
var best_times: Array[float] = [-1,-1,-1,-1,-1]
var medal_img: Array[float] = [5,5,5,5,5]
var car_stats: Array[CarStats] = [
	preload("res://car_stats/StarterStats.tres"),
	preload("res://car_stats/MidStats.tres"),
	preload("res://car_stats/MainStats.tres"),
	preload("res://car_stats/InsaneStats.tres"),
]
## Index into previous array (maybe not the best solution?)
var current_stat = 2
var are_pads_activated: Dictionary[String, bool] = {
	"volcano": true,
	"forest": true,
	"lake": true,
	"desert": true,
	"mountain": true
}
