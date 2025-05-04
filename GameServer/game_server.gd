extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)

const PORT = 7000
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	start_server()

func start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	ServerLogger.info(str("Server started"))

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	Replication.players.clear()
	Replication.update_player_register.rpc(Replication.players)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id : int) -> void:
	ServerLogger.info(str(str(id), " Connected !"))
	register_player(id)

func register_player(id : int) -> void:
	ServerLogger.info(str("Player : ", str(id), " Registered."))
	Replication.players[id] = {}
	Replication.update_player_register.rpc(Replication.players)

func _on_player_disconnected(id):
	ServerLogger.info(str(str(id), " Disconnected."))
	Replication.players.erase(id)
	Replication.update_player_register.rpc(Replication.players)
	player_disconnected.emit(id)
