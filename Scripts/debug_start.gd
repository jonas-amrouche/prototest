extends Node

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		get_tree().call_deferred("change_scene_to_file", "res://GameServer/game_server.tscn")
	else:
		if OS.get_cmdline_args().size() > 1:
			Replication.client_infos["name"] = OS.get_cmdline_args()[1]
			if OS.get_cmdline_args()[1] == "player1":
				get_window().position = Vector2i(30, 30)
			else:
				get_window().position = Vector2i(560, 340)
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/game_client.tscn")
