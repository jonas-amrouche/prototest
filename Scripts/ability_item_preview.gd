extends Panel

var ability : Ability

@onready var adility_name = $AbilityContainer/AbilityName
@onready var adility_desc = $AbilityContainer/AbilityDesc
@onready var adility_icon = $AbilityContainer/AbilityIcon
@onready var adility_cap = $AbilityContainer/AbilityCap

func _ready():
	if ability:
		adility_name.text = ability.name
		adility_desc.text = ability.description
		adility_icon.texture = ability.icon
		adility_name.label_settings.set("font_color", Basics.DAMAGE_COLOR[ability.damage_type])
		adility_cap.text = "->" + str(ability.damage_cap)
