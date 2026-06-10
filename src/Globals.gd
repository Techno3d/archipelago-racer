extends Node

signal checkpoint_passed(id: int)

signal set_max_checkpoints(num: int)



var goal: TimeTrials
var car_stats: Array[CarStats] = [
	preload("res://car_stats/InsaneStats.tres"),
	preload("res://car_stats/MainStats.tres"),
	preload("res://car_stats/MidStats.tres"),
	preload("res://car_stats/StarterStats.tres"),
]
## Index into previous array (maybe not the best solution?)
var current_stat = 1
var is_boost_pads_activated = false
