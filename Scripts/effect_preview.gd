extends PanelContainer

var effect : Effect

@onready var eff_name = $EffectPad/EffectContainer/TitleContainer/Pad/EffectName
@onready var eff_desc = $EffectPad/EffectContainer/Desc
@onready var eff_duration = $EffectPad/Duration
@onready var eff_icon = $EffectPad/EffectContainer/TitleContainer/IconCont/Icon

const DEBUFF_COLOR = Color(0.147, 0.045, 0.039)
const BUFF_COLOR = Color(0.025, 0.098, 0.06)

func _ready():
	eff_name.text = effect.name
	get("theme_override_styles/panel").set("bg_color", DEBUFF_COLOR if effect.debuff else BUFF_COLOR)
	eff_desc.text = effect.description
	eff_duration.text = str(effect.duration) + " s"
	eff_icon.set_texture(effect.icon)
