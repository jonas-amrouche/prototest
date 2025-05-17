extends Node

# CLIENT NOT DIRECTLY USED BY SERVER
var client_infos := {}

# CLIENT AND SERVER
var players := {}
var players_loaded := {}

const PORT := 7432
const DEFAULT_SERVER_IP := "localhost" # IPv4 localhost

signal enter_class_select
signal player_locked_class(id : int, class_locked : Basics.Class)
signal enter_game_loading
signal player_load_finished(id : int)
signal load_finished()

# Called by server to update client
@rpc("any_peer", "reliable", "call_remote")
func update_player_register(players_infos : Dictionary) -> void:
	players = players_infos
	#print_rich(("[color=red]server" if multiplayer.is_server() else "[color=blue]client"), "[/color] : ", players)

# Called by client, executed by server, then update_player_register is called to update client
@rpc("any_peer", "reliable")
func update_player_infos(client_id : int, new_client_info : Dictionary) -> void:
	players[client_id] = new_client_info
	update_player_register.rpc(players)
	#print_rich(("[color=red]server" if multiplayer.is_server() else "[color=blue]client"), "[/color] : ", players)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded(id : int):
	if multiplayer.is_server():
		players_loaded[id] = true
		player_load_finished.emit(id)
		if players_loaded.size() == players.size():
			rpc("launch_game")
			launch_game()

# Called by server, executed by server and peers
@rpc("any_peer", "reliable")
func launch_game() -> void:
	load_finished.emit()

@rpc("any_peer", "reliable")
func launch_class_select() -> void:
	enter_class_select.emit()

@rpc("any_peer", "reliable")
func lock_class(client_id : int, class_selected : Basics.Class) -> void:
	players[client_id]["class"] = class_selected
	player_locked_class.emit(client_id, class_selected)
	# TODO should check if everybody locked before loading
	launch_game_loading()

func launch_game_loading() -> void:
	enter_game_loading.emit()
