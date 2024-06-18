extends Node3D

const id = "plant"

@export var harvest_time = 2.5
@export var harvest_ressource = "koka_seed"
@export var harvest_quantity = 3
@export var plant_skin = 0

var player_reference

@onready var harvest_timer = $Harvest

func _ready():
	harvest_timer.wait_time = harvest_time

func start_harvesting(player : Object):
	player_reference = player
	harvest_timer.start()

func stop_harvesting():
	harvest_timer.stop()

func _on_harvest_timeout():
	player_reference.interaction_success(id, harvest_ressource, harvest_quantity)
