extends PanelContainer

@export var component : Component
@export var quantity : int
signal drag_component(slot : Object)
signal drop_component(slot : Object)

@onready var icon := $CompCont/MarginIcon/Icon
@onready var quantity_lab := $CompCont/MarginQuantity/Quantity
@onready var comp_container := $CompCont

func _ready():
	if component:
		icon.texture = component.icon
		quantity_lab.text = str(quantity)
	else:
		icon.texture = null
		quantity_lab.text = ""

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_component.emit(self)

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if component:
				grabbed = true
				comp_container.z_index = 1
				drag_component.emit(self)
		else:
			comp_container.z_index = 0
			comp_container.position = Vector2(2.0, 2.0)
			grabbed = false
	if event is InputEventMouseMotion and grabbed:
		comp_container.position = get_viewport().get_mouse_position() - global_position - size/2.0
