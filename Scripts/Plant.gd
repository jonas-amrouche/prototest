extends Node3D

const id := "plant"

@export var plant : Plant

var grown := true
var player_reference : Object
var mesh : Object
var component_model : Object

@onready var harvest_timer := $Harvest
@onready var grow_timer := $Grow

func _ready() -> void:
	mesh = plant.mesh_model.instantiate()
	component_model = mesh.get_child(1)
	add_child(mesh)
	grow_timer.wait_time = plant.grow_time
	harvest_timer.wait_time = plant.harvest_time

func start_harvesting(player : Object) -> void:
	player_reference = player
	harvest_timer.start()

func stop_harvesting() -> void:
	harvest_timer.stop()

func _on_harvest_timeout() -> void:
	player_reference.interaction_success(id, plant.harvest_components, plant.harvest_quantities)
	if plant.vanish_on_take:
		queue_free()
	else:
		grown = false
		component_model.set_visible(false)
		grow_timer.start()

func _on_grow_timeout() -> void:
	grown = true
	component_model.set_visible(true)
