extends PanelContainer

@export var ability : Ability
@export var keybind : String
signal drag_ability(slot : Object)
signal drop_ability(slot : Object)

@onready var icon = $MarginContainer/Icon
@onready var keybind_label = $MarginContainer/Keybind

func _ready() -> void:
	update_slot()

func update_slot() -> void:
	keybind_label.set_text(keybind.replace("(Physical)", ""))
	if ability:
		icon.set_texture(ability.icon)
	else:
		icon.set_texture(null)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_ability.emit(self)

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if ability:
				grabbed = true
				icon.z_index = 1
				drag_ability.emit(self)
		else:
			icon.z_index = 0
			icon.position = Vector2(2.0, 2.0)
			grabbed = false
			#var _grab_pos = get_viewport().get_mouse_position()
			#var _invetory_area = Rect2(get_node("..").global_position, get_node("..").size)
			#if _grab_pos.x > _invetory_area.position.x and _grab_pos.x < _invetory_area.end.x and _grab_pos.y > _invetory_area.position.y and _grab_pos.y < _invetory_area.end.y:
				#if !grabbed:
					#drop_ability.emit(self)
			#else:
				#icon.position = Vector2(2.0, 2.0)
			#grabbed = false
	if event is InputEventMouseMotion and grabbed:
		icon.position = get_viewport().get_mouse_position() - global_position - size/2.0
