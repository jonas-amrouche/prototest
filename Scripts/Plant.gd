extends Node3D

const id = "plant"

@export var plant : Plant

var grown = true
var player_reference

@onready var harvest_timer := $Harvest
@onready var grow_timer := $Grow
@onready var fruit_model := $FruitModel

func _ready():
	grow_timer.wait_time = plant.grow_time
	harvest_timer.wait_time = plant.harvest_time

func start_harvesting(player : Object):
	player_reference = player
	harvest_timer.start()

func stop_harvesting():
	harvest_timer.stop()

func _on_harvest_timeout():
	player_reference.interaction_success(id, plant.harvest_components, plant.harvest_quantities)
	if plant.vanish_on_take:
		queue_free()
	else:
		grown = false
		fruit_model.set_visible(false)
		grow_timer.start()

func _on_grow_timeout():
	grown = true
	fruit_model.set_visible(true)
