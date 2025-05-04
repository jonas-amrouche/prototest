extends Node

# CLIENT NOT DIRECTLY USED BY SERVER
var client_infos = {}

# CLIENT AND SERVER
var players = {}
var players_loaded = 0

#@rpc("authority", "reliable")
#func register_player(id : int) -> void:
	#ServerLogger.info(str("Player : ", str(id), " Registered."))
	#var new_player_id = multiplayer.get_remote_sender_id()
	#players[new_player_id] = {}
	#retrieve_players_infos()

@rpc("any_peer", "reliable")
func update_player_register(players_infos : Dictionary) -> void:
	players = players_infos
	print(players_infos)

@rpc("any_peer", "reliable")
func update_player_info(client_id : int, new_client_info : Dictionary) -> void:
	players[client_id] = new_client_info
	print(players)

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0
