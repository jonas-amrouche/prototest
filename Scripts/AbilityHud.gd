extends PanelContainer

@export var ability : Ability
@export var item : Item
@export var keybind : String
@export var cooldown_left := 0.0
signal drag_ability(slot : Object)
signal drop_ability(slot : Object)
signal mouse_entered_ability(abl : Ability)

@onready var icon = $MarginContainer/IconContainer/Icon
@onready var item_icon = $ItemIconContainer/ItemIcon
@onready var keybind_label = $MarginContainer/Keybind
@onready var cooldown_label = $CooldownLabel
@onready var cooldown_progress = $MarginContainer/CoolDownProgress

func _ready() -> void:
	if cooldown_left != 0.0:
		start_cooldown()
	elif ability:
		cooldown_left = ability.cooldown
	update_slot()

func update_slot() -> void:
	keybind_label.set_text(keybind.replace("(Physical)", ""))
	if ability:
		icon.set_texture(ability.icon)
		item_icon.set_texture(item.icon)
	else:
		icon.set_texture(null)
		item_icon.set_texture(null)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_ability.emit(self)

func use_ability() -> void:
	cooldown_label.hide()
	cooldown_progress.value = 100.0

func start_cooldown() -> void:
	cooldown_label.show()
	create_tween().tween_method(Callable(self, "update_cooldown"), cooldown_left, 0.0, cooldown_left)

func update_cooldown(time_left : float) -> void:
	if time_left == 0.0:
		cooldown_label.text = ""
		cooldown_progress.value = 0.0
		if ability:
			cooldown_left = ability.cooldown
		return
	if time_left > 1.0:
		cooldown_label.text = str(int(time_left))
	else:
		cooldown_label.text = str(int(time_left*10.0)/10.0)
	cooldown_progress.value = time_left/ability.cooldown * 100.0

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if ability:
				grabbed = true
				icon.z_index = 1
				drag_ability.emit(self)
				mouse_exited.emit()
		else:
			icon.z_index = 0
			icon.position = Vector2(2.0, 2.0)
			grabbed = false
	if event is InputEventMouseMotion:
		if grabbed:
			icon.position = get_viewport().get_mouse_position() - global_position - size/2.0

func _on_mouse_entered():
	if !grabbed:
		mouse_entered_ability.emit(self)
