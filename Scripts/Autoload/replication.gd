extends Node

# ── State ─────────────────────────────────────────────────────────────────────

var client_infos : Dictionary = {}
var players      : Dictionary = {}  # peer_id -> player info dict
var players_loaded : Dictionary = {}

const PORT                := 7432
const DEFAULT_SERVER_IP   := "localhost"

# ── Signals ───────────────────────────────────────────────────────────────────

signal enter_class_select
signal player_locked_class(id : int, class_locked : Basics.ClassType)
signal enter_game_loading
signal player_load_finished(id : int)
signal load_finished

# ── Player registration ───────────────────────────────────────────────────────

## Called by server when a new peer connects.
## Sends the new peer a full snapshot of current players (one-time sync),
## then notifies all existing peers about the newcomer only.
func register_new_player(new_id : int, info : Dictionary) -> void:
	players[new_id] = info

	# Send the new peer a full snapshot so they know about everyone
	_send_full_snapshot.rpc_id(new_id, players)

	# Notify all other peers about this single new player only
	_notify_player_joined.rpc(new_id, info)

## Called by server when a peer disconnects.
func unregister_player(id : int) -> void:
	players.erase(id)
	_notify_player_left.rpc(id)

# ── Player info updates ───────────────────────────────────────────────────────

## Called by a client to update their own info on the server.
## Server applies it and broadcasts only the changed entry.
@rpc("any_peer", "reliable")
func update_player_infos(client_id : int, new_info : Dictionary) -> void:
	if not multiplayer.is_server():
		return
	players[client_id] = new_info
	# Broadcast only this player's updated entry — not the whole dict
	_notify_player_updated.rpc(client_id, new_info)

# ── RPC: server → clients ─────────────────────────────────────────────────────

## Full snapshot sent only to a newly connected peer.
@rpc("authority", "reliable", "call_remote")
func _send_full_snapshot(snapshot : Dictionary) -> void:
	players = snapshot

## Targeted: tell all peers about one new player.
@rpc("authority", "reliable")
func _notify_player_joined(id : int, info : Dictionary) -> void:
	players[id] = info

## Targeted: tell all peers one player updated their info.
@rpc("authority", "reliable")
func _notify_player_updated(id : int, info : Dictionary) -> void:
	players[id] = info

## Tell all peers one player left.
@rpc("authority", "reliable")
func _notify_player_left(id : int) -> void:
	players.erase(id)

# ── Game flow RPCs ────────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func launch_class_select() -> void:
	enter_class_select.emit()

@rpc("any_peer", "reliable")
func lock_class(client_id : int, class_selected : Basics.ClassType) -> void:
	players[client_id]["class"] = class_selected
	player_locked_class.emit(client_id, class_selected)
	_enter_game_loading_rpc.rpc()

@rpc("authority", "reliable")
func _enter_game_loading_rpc() -> void:
	enter_game_loading.emit()

@rpc("any_peer", "call_local", "reliable")
func player_loaded(id : int) -> void:
	print("player_loaded called: ", id, " is_server: ", multiplayer.is_server())
	if not multiplayer.is_server():
		return
	players_loaded[id] = true
	player_load_finished.emit(id)
	print("players_loaded: ", players_loaded.size(), " / players: ", players.size(), " keys: ", players.keys())
	if players_loaded.size() == players.size():
		_launch_game_rpc.rpc()

@rpc("any_peer", "reliable", "call_local")
func _launch_game_rpc() -> void:
	load_finished.emit()
