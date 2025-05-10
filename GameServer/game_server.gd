extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
#signal player_connected(peer_id, player_info)
#signal player_disconnected(peer_id)

@onready var server_logger = $ServerLogger
var game_scene

const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	Replication.enter_class_select.connect(_enter_class_select)
	Replication.player_locked_class.connect(_player_lock_class)
	Replication.enter_game_loading.connect(_enter_game_loading)
	Replication.player_load_finished.connect(_player_load_finished)
	Replication.load_finished.connect(_load_finished)
	
	var _error = start_server()
	if _error != Error.OK:
		server_logger.error(str("Error starting server : ", str(_error)))
	else:
		load_game()

func load_game() -> void:
	server_logger.info("Loading game scene.")
	var _game_scene = load("res://Scenes/game.tscn").instantiate()
	add_child(_game_scene, true)
	game_scene = _game_scene

func start_server() -> Error:
	var _peer = ENetMultiplayerPeer.new()
	var _error = _peer.create_server(Replication.PORT, MAX_CONNECTIONS)
	if _error:
		return _error
	multiplayer.multiplayer_peer = _peer
	server_logger.info("Server started")
	return Error.OK

func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null
	Replication.players.clear()

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id : int) -> void:
	server_logger.info(str(str(id), " Connected !"))
	register_player(id)

func register_player(id : int) -> void:
	server_logger.info(str("Player : ", str(id), " Registered."))
	Replication.players[id] = {}
	Replication.update_player_register.rpc(Replication.players)

func _on_player_disconnected(id : int) -> void:
	server_logger.info(str(str(id), " Disconnected."))
	Replication.players.erase(id)
	Replication.update_player_register.rpc(Replication.players)
	#player_disconnected.emit(id)

func _enter_class_select() -> void:
	server_logger.info("Entering class select.")

func _player_lock_class(id : int, class_locked : Basics.Class) -> void:
	server_logger.info(str("player ", str(id), "(", str(Replication.players[id]["name"]), ") has locked ", str(Basics.CLASS_TEXT[class_locked]), "."))

func _enter_game_loading() -> void:
	
	server_logger.info("Entering loading screen.")

func _player_load_finished(id : int) -> void:
	server_logger.info(str("player ", str(id), "(", str(Replication.players[id]["name"]), ") has loaded"))

func _load_finished() -> void:
	server_logger.info("all players finished loading, entering game.")
	if game_scene:
		game_scene.launch_game()
	else:
		server_logger.error("game scene is not loaded.")
