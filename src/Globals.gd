extends Node

signal checkpoint_passed(id: int)

signal set_max_checkpoints(num: int)

func _ready():
	if Archipelago.conn:
		_wire_ap(Archipelago.conn, {})
	Archipelago.connected.connect(_wire_ap)

func _wire_ap(conn: ConnectionInfo, json: Dictionary):
	current_stat = 0
	print(json)
	var death_link = 1.0 == json.get("slot_data").get("death_link")
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
