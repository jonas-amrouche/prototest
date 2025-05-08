extends Node

# CLIENT NOT DIRECTLY USED BY SERVER
var client_infos = {}

# CLIENT AND SERVER
var players = {}
var players_loaded = 0

const PORT = 7432
const DEFAULT_SERVER_IP = "localhost" # IPv4 localhost

signal enter_role_select
signal player_locked_role(id : int, role : Basics.Role)
signal enter_game_loading
signal player_load_finished(id : int)
signal load_finished()

@rpc("any_peer", "reliable")
func update_player_register(players_infos : Dictionary) -> void:
	players = players_infos

@rpc("any_peer", "reliable")
func update_player_infos(client_id : int, new_client_info : Dictionary) -> void:
	players[client_id] = new_client_info

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded(id : int):
	if multiplayer.is_server():
		players_loaded += 1
		player_load_finished.emit(id)
		if players_loaded == players.size():
			load_finished.emit()
			players_loaded = 0

@rpc("any_peer", "reliable")
func launch_role_select() -> void:
	enter_role_select.emit()

@rpc("any_peer", "reliable")
func lock_role(client_id : int, role_selected : Basics.Role) -> void:
	players[client_id]["role"] = role_selected
	player_locked_role.emit(client_id, role_selected)
	# TODO should check if everybody locked before loading
	launch_game_loading()

func launch_game_loading() -> void:
	enter_game_loading.emit()
