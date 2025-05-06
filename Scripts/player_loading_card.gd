extends PanelContainer

var player_infos : Dictionary

@onready var skin_icon = $Pad/Skin
@onready var pseudo_label = $Pad/Infos/Pseudo
@onready var role_label = $Pad/Infos/Role

func _ready() -> void:
	print(player_infos)
	
	if player_infos.has("name"):
		pseudo_label.text = player_infos["name"]
	else:
		pseudo_label.text = "Not set"
	
	if player_infos.has("role"):
		role_label.text = Basics.ROLE_TEXT[player_infos["role"]]
	else:
		role_label.text = "Not set"
