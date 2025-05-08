extends Node

var state : Basics.ClientState = Basics.ClientState.DISCONNECTED

var client_id: int

func set_state(sta: Basics.ClientState) -> void:
	state = sta
