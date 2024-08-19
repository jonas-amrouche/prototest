extends PanelContainer

@export var component : Component
@export var quantity : int

signal mouse_entered_component(comp : Component)

@onready var icon := $CompCont/MarginIcon/Icon
@onready var quantity_lab := $CompCont/MarginQuantity/Quantity
@onready var comp_container := $CompCont

func _ready():
	update_component()

func update_component() -> void:
	if component:
		icon.texture = component.icon
		quantity_lab.text = str(quantity)
	else:
		icon.texture = null
		quantity_lab.text = ""

func component_change_preview(new_value : int) -> void:
	quantity_lab.text = str(new_value)
	quantity_lab.label_settings.set("font_color", Color(0.828, 0.777, 0.039))
	get("theme_override_styles/panel").set("bg_color", Color(0.698, 0.133, 0.055))

func _on_mouse_entered():
	mouse_entered_component.emit(component)
