extends PanelContainer

@export var ability : Ability
@export var item : Item
@export var keybind : String
@export var cooldown_left := 0.0
signal drag_ability(slot : Object)
signal drop_ability(slot : Object)

@onready var icon = $MarginContainer/IconContainer/Icon
@onready var item_icon = $ItemIconContainer/ItemIcon
@onready var keybind_label = $MarginContainer/Keybind
@onready var rarity_frame = $MarginContainer/RarityFrame
@onready var cooldown_label = $CooldownLabel

func _ready() -> void:
	if cooldown_left != 0.0:
		use_ability()
	elif ability:
		cooldown_left = ability.cooldown
	update_slot()

func update_slot() -> void:
	keybind_label.set_text(keybind.replace("(Physical)", ""))
	if ability:
		icon.set_texture(ability.icon)
		item_icon.set_texture(item.icon)
		rarity_frame.get("theme_override_styles/panel").set("bg_color", Basics.RARITY_COLORS[item.rarity])
	else:
		icon.set_texture(null)
		item_icon.set_texture(null)
		rarity_frame.get("theme_override_styles/panel").set("bg_color", Color(1.0, 1.0, 1.0, 0.0))

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_ability.emit(self)

func use_ability() -> void:
	create_tween().tween_method(Callable(self, "update_cooldown"), cooldown_left, 0.0, cooldown_left)

func update_cooldown(time_left : float) -> void:
	if time_left == 0.0:
		cooldown_label.text = ""
		return
	cooldown_label.text = str(int(time_left))

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
