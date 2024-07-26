extends Panel

var ability : Ability

@onready var adility_name = $AbilityContainer/AbilityName
@onready var adility_desc = $AbilityContainer/AbilityDesc
@onready var adility_icon = $AbilityContainer/AbilityIcon

func _ready():
	if ability:
		adility_name.text = ability.name
		adility_desc.text = ability.description
		adility_icon.texture = ability.icon

