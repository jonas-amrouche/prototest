extends Node3D

const id = "plant"

@export var vanish_on_take := false
@export var harvest_time := 2.5
@export var harvest_ressource := "koka_seed"
@export var harvest_quantity := 3
@export var grow_time := 5.0
@export var plant_skin := 0

var grown = true
var player_reference

@onready var harvest_timer := $Harvest
@onready var grow_timer := $Grow
@onready var fruit_model := $FruitModel

func _ready():
	grow_timer.wait_time = grow_time
	harvest_timer.wait_time = harvest_time

func start_harvesting(player : Object):
	player_reference = player
	harvest_timer.start()

func stop_harvesting():
	harvest_timer.stop()

func _on_harvest_timeout():
	player_reference.interaction_success(id, harvest_ressource, harvest_quantity)
	if vanish_on_take:
		queue_free()
	else:
		grown = false
		fruit_model.set_visible(false)
		grow_timer.start()

func _on_grow_timeout():
	grown = true
	fruit_model.set_visible(true)
