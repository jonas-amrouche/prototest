extends Node3D

var pre_camp = preload("res://Scenes/Props/Camp.tscn")
var pre_player = preload("res://Scenes/Player.tscn")


func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	map_generation()
	spawn_player(get_node("Camp/PlayerSpawn/1").global_position)

func generate_camp(pos : Vector3, scl : Vector3) -> void:
	var _new_camp = pre_camp.instantiate()
	_new_camp.position = pos
	_new_camp.scale = scl
	add_child(_new_camp)

func map_generation() -> void:
	generate_camp(Vector3(-200, 0, 200), Vector3(1.0, 1.0, 1.0))
	generate_camp(Vector3(200, 0, -200), Vector3(-1.0, 1.0, -1.0))

func spawn_player(pos : Vector3) -> void:
	var _new_player = pre_player.instantiate()
	_new_player.position = pos
	add_child(_new_player)
