extends Control

var category_selected := 0
var item_craft_selected : Item
var item_in_decompose
var hover_craft_button : bool
var auto_attack_id := 0

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_hud = preload("res://Scenes/UI/ItemHud.tscn")
var pre_ability_hud = preload("res://Scenes/UI/AbilityHud.tscn")
var pre_item_craft = preload("res://Scenes/UI/ItemCraft.tscn")
var pre_stat_hud = preload("res://Scenes/UI/StatHud.tscn")
var pre_xp_gem_hud = preload("res://Scenes/UI/ExperienceGem.tscn")
var pre_effect_hud = preload("res://Scenes/UI/EffectHud.tscn")
var pre_item_preview = preload("res://Scenes/UI/ItemPreview.tscn")
var pre_ability_preview = preload("res://Scenes/UI/AbilityPreview.tscn")
var pre_component_preview = preload("res://Scenes/UI/ComponentPreview.tscn")
var pre_effect_preview = preload("res://Scenes/UI/EffectPreview.tscn")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

@onready var player := get_node("..").get_node("..")
@onready var scoreboard := $ScoreBoard
@onready var chat := $Chat
@onready var craft_tab := $CraftComponents/CraftAvailable
@onready var craft_available_container := $CraftComponents/CraftAvailable/Pad/Order/CraftItemPanel/CraftAvailable
@onready var craft_available_nothing := $CraftComponents/CraftAvailable/Pad/Order/CraftItemPanel/Nothing
@onready var decompose_tab := $DecomposeItem
@onready var decompose_button := $DecomposeItem/Pad/Decompose
@onready var decompose_container := $DecomposeItem/Pad/DecomposeCont
@onready var component_list := $CraftComponents/Components/Pad/CompList
@onready var item_list = $Items/Pad/ItemList
@onready var ability_list = $ActionPanel/AbilityBar/Pad/AbilityList
@onready var stats_list = $Stats/MarginContainer/StatList
@onready var channeling_bar := $ChannelingBar
@onready var souls_label := $Souls/SoulsLabel
@onready var mini_map := $MiniMap
@onready var item_craft_button := $CraftComponents/CraftAvailable/Pad/Order/Craft
@onready var health_bar_hud := $ActionPanel/BarContainer/Pad/HealthBar
@onready var experience_gem_container := $ExpPad/ExpContainer
@onready var effect_container := $EffectPad/EffectContainer
@onready var level_label_hud := $LevelPan/LevelInd

var item_preview
var component_preview
var effect_preview
var ability_preview

func _process(_delta):
	mini_map.update_camera_position(player.camera.global_position, player.camera_base_marker.position)
	mini_map.update_player_position(player.global_position)
	update_previews()

func init_map_data(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, interests_data : Dictionary, river_noise_tex : NoiseTexture2D) -> void:
	mini_map.initialize_minimap(Basics.MAP_SIZE, paths_data, bases_data, interests_data, river_noise_tex)

func update_info_bars() -> void:
	player.health_bar.value = float(player.health) / float(player.stats.max_health) * 100.0
	player.level_label.text = str(player.level)
	health_bar_hud.value = float(player.health) / float(player.stats.max_health) * 100.0
	level_label_hud.text = str(player.level)
	
	for i in experience_gem_container.get_children():
		i.free()
	
	for i in range(player.max_experience):
		var new_xp_gem = pre_xp_gem_hud.instantiate()
		new_xp_gem.material.set_shader_parameter("filled", player.experience > i)
		experience_gem_container.add_child(new_xp_gem)

func select_item(item : Item) -> void:
	item_craft_selected = item
	item_craft_button.disabled = !player.is_item_craftable(item) or player.items.has(item)
	for i in craft_available_container.get_children():
		if i.item == item:
			continue
		i.unselect_item()

func add_item_in_decompose(item : Item) -> void:
	if item_in_decompose:
		player.obtain_item(item_in_decompose)
	player.lose_item(item)
	item_in_decompose = item
	update_decompose()

func update_decompose() -> void:
	for i in decompose_container.get_children():
		i.queue_free()
	
	var _new_item_slot = pre_item_hud.instantiate()
	_new_item_slot.connect("drop_item", Callable(self, "drop_item_decompose"))
	_new_item_slot.connect("drag_item", Callable(self, "drag_item"))
	_new_item_slot.connect("mouse_entered_item", Callable(self, "show_item_preview"))
	_new_item_slot.connect("mouse_exited", Callable(self, "hide_item_preview"))
	if item_in_decompose:
		_new_item_slot.item = item_in_decompose
	decompose_container.add_child(_new_item_slot)

func clear_decompose() -> void:
	if item_in_decompose:
		if player.is_items_full():
			_on_decompose_pressed()
			return
		player.obtain_item(item_in_decompose)
	item_in_decompose = null
	update_decompose()

func update_craft_available() -> void:
	item_craft_selected = null
	item_craft_button.disabled = true
	for i in craft_available_container.get_children():
		i.queue_free()
	
	for i in all_item_base.base:
		if player.is_item_craftable(i):
			var _new_item_craft = pre_item_craft.instantiate()
			_new_item_craft.item = i
			_new_item_craft.select_item.connect(Callable(self, "select_item"))
			_new_item_craft.connect("mouse_entered_item", Callable(self, "show_item_preview"))
			_new_item_craft.connect("mouse_exited", Callable(self, "hide_item_preview"))
			craft_available_container.add_child(_new_item_craft)
	
	craft_available_nothing.set_visible(craft_available_container.get_child_count() == 0)

func update_abilities() -> void:
	# Clear ability bar
	for a_slot in ability_list.get_children():
		a_slot.queue_free()
	
	# Get item data
	var _abilities_had = []
	var _item_link = Dictionary()
	for i in player.items:
		if i == null:
			continue
		for a in i.abilities:
			_abilities_had.append(a)
			_item_link.merge({a : i})
	
	# Allow slot binding of ability
	for a in _abilities_had:
		if player.abilities.has(a):
			continue
		player.abilities[player.abilities.find(null)] = a
	for a in player.abilities:
		if !_abilities_had.has(a):
			player.abilities[player.abilities.find(a)] = null
			#TODO Si il y a trop de sort pour l'instant ça va faire de la merde
	
	# Populate ability bar
	for a in range(player.abilities.size()):
		var _new_ability_hud = pre_ability_hud.instantiate()
		if player.abilities[a]:
			if player.ability_machine.get_ability_cooldown(player.abilities[a]):
				_new_ability_hud.cooldown_left = player.ability_machine.get_ability_cooldown(player.abilities[a])
			_new_ability_hud.ability = player.abilities[a]
			_new_ability_hud.item = _item_link.get(player.abilities[a])
		_new_ability_hud.is_auto_attack = a == auto_attack_id
			
		for i in InputMap.get_actions():
			if i.begins_with("ability") and i.ends_with(str(a+1)):
				_new_ability_hud.keybind = InputMap.action_get_events(i)[0].as_text()
		_new_ability_hud.connect("drag_ability", Callable(self, "drag_ability"))
		_new_ability_hud.connect("drop_ability", Callable(self, "drop_ability"))
		_new_ability_hud.connect("mouse_entered_ability", Callable(self, "show_ability_preview"))
		_new_ability_hud.connect("mouse_exited", Callable(self, "hide_ability_preview"))
		_new_ability_hud.connect("assign_auto_attack", Callable(self, "assign_auto_attack"))
		ability_list.add_child(_new_ability_hud)

func update_items() -> void:
	# Clear item bar
	for i in item_list.get_children():
		i.queue_free()
	
	# Populate item bar
	for i in player.items:
		var _new_item_hud = pre_item_hud.instantiate()
		if i:
			_new_item_hud.item = i
		_new_item_hud.connect("drop_item", Callable(self, "drop_item"))
		_new_item_hud.connect("drag_item", Callable(self, "drag_item"))
		_new_item_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		item_list.add_child(_new_item_hud)

func show_item_preview(item : Item) -> void:
	if item_preview:
		item_preview.queue_free()
	if item:
		item_preview = pre_item_preview.instantiate()
		item_preview.hide()
		item_preview.item = item
		add_child(item_preview)

func hide_item_preview() -> void:
	if item_preview:
		item_preview.queue_free()
		item_preview = null

func show_ability_preview(ability_ref : Object) -> void:
	if ability_ref.ability:
		ability_preview = pre_ability_preview.instantiate()
		ability_preview.ability = ability_ref.ability
		add_child(ability_preview)
		ability_preview.position = ability_ref.global_position - Vector2(ability_preview.size.x/2.0 - ability_ref.size.x/2.0, ability_preview.size.y + 10.0)

func hide_ability_preview() -> void:
	if ability_preview:
		ability_preview.queue_free()
		ability_preview = null

func assign_auto_attack(ability_ref : Object) -> void:
	auto_attack_id = ability_ref.get_index()
	update_abilities()

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(player.components.size()):
		var _new_component_hud = pre_component_hud.instantiate()
		_new_component_hud.component = player.components.keys()[i]
		_new_component_hud.quantity = player.components.values()[i]
		_new_component_hud.connect("mouse_entered_component", Callable(self, "show_component_preview"))
		_new_component_hud.connect("mouse_exited", Callable(self, "hide_component_preview"))
		component_list.add_child(_new_component_hud)
		if hover_craft_button and item_craft_selected and item_craft_selected.craft_recipe.has(player.components.keys()[i]):
			_new_component_hud.component_change_preview(player.components.values()[i] - item_craft_selected.craft_recipe.get(player.components.keys()[i]))

func update_effects() -> void:
	for i in effect_container.get_children():
		i.queue_free()
	for i in range(player.effect_machine.active_effects.size()):
		var _new_effect_hud = pre_effect_hud.instantiate()
		_new_effect_hud.effect = player.effect_machine.active_effects.keys()[i]
		_new_effect_hud.connect("mouse_entered_effect", Callable(self, "show_effect_preview"))
		_new_effect_hud.connect("mouse_exited", Callable(self, "hide_effect_preview"))
		effect_container.add_child(_new_effect_hud)

func show_effect_preview(effect : Effect) -> void:
	if effect_preview:
		effect_preview.queue_free()
	if effect:
		effect_preview = pre_effect_preview.instantiate()
		effect_preview.effect = effect
		add_child(effect_preview)

func hide_effect_preview() -> void:
	if effect_preview:
		effect_preview.queue_free()
		effect_preview = null

func show_component_preview(component : Component) -> void:
	if component_preview:
		component_preview.queue_free()
	if component:
		component_preview = pre_component_preview.instantiate()
		component_preview.component = component
		add_child(component_preview)

func hide_component_preview() -> void:
	if component_preview:
		component_preview.queue_free()
		component_preview = null

func update_previews() -> void:
	if component_preview:
		component_preview.position = get_viewport().get_mouse_position() - Vector2(0.0, component_preview.size.y)
	if effect_preview:
		effect_preview.position = get_viewport().get_mouse_position() - Vector2(effect_preview.size.x, effect_preview.size.y)
	if item_preview:
		item_preview.position = get_viewport().get_mouse_position() - Vector2(0.0, item_preview.size.y)

func update_stats_hud() -> void:
	for i in stats_list.get_children():
		i.queue_free()
	
	for i in range(player.stats.size()):
		var _new_stat_hud = pre_stat_hud.instantiate()
		_new_stat_hud.stat_value = player.stats.values()[i]
		_new_stat_hud.stat = Basics.stats_data[player.stats.keys()[i]]
		stats_list.add_child(_new_stat_hud)

var dragged_ability_slot : Object
func drag_ability(slot : Object) -> void:
	dragged_ability_slot = slot

func drop_ability(slot : Object) -> void:
	if dragged_ability_slot:
		var _temp_ability = slot.ability
		player.abilities[ability_list.get_children().find(slot)] = dragged_ability_slot.ability
		player.abilities[ability_list.get_children().find(dragged_ability_slot)] = _temp_ability
		update_abilities()
		dragged_ability_slot = null

var dragged_component_slot : Object
func drag_component(slot : Object) -> void:
	dragged_component_slot = slot

func drop_component(slot : Object) -> void:
	if dragged_component_slot:
		var _temp_component = slot.component
		var _temp_quantity = slot.quantity if slot.component else null
		player.components[component_list.get_children().find(slot)] = dragged_component_slot.component
		player.comp_quantities[component_list.get_children().find(slot)] = dragged_component_slot.quantity
		player.components[component_list.get_children().find(dragged_component_slot)] = _temp_component
		player.comp_quantities[component_list.get_children().find(dragged_component_slot)] = _temp_quantity
		update_components()
		dragged_component_slot = null

var dragged_item_slot : Object
func drag_item(slot : Object) -> void:
	dragged_item_slot = slot
	if slot.item == item_in_decompose:
		decompose_button.disabled = true

func drop_item(slot : Object) -> void:
	if dragged_item_slot:
		if dragged_item_slot.item == item_in_decompose:
			player.items[item_list.get_children().find(slot)] = dragged_item_slot.item
			item_in_decompose = null
			update_items()
			update_abilities()
			update_decompose()
			dragged_item_slot = null
			return
		player.items[item_list.get_children().find(slot)] = dragged_item_slot.item
		player.items[item_list.get_children().find(dragged_item_slot)] = slot.item
		update_items()
		dragged_item_slot = null

func drop_item_decompose(slot : Object) -> void:
	if dragged_item_slot:
		item_in_decompose = dragged_item_slot.item
		player.items[item_list.get_children().find(dragged_item_slot)] = slot.item
		update_items()
		update_abilities()
		update_decompose()
		dragged_item_slot = null
		decompose_button.disabled = false

func _on_craft_pressed():
	if !player.is_items_full():
		if player.in_base:
			for c in range(item_craft_selected.craft_recipe.size()):
				player.lose_component(item_craft_selected.craft_recipe.keys()[c], item_craft_selected.craft_recipe.values()[c])
		player.obtain_item(item_craft_selected)
		item_craft_selected = null
		item_craft_button.disabled = true
		update_components()

func _on_decompose_pressed():
	if item_in_decompose:
		for i in range(item_in_decompose.craft_recipe.size()):
			player.obtain_component(item_in_decompose.craft_recipe.keys()[i], item_in_decompose.craft_recipe.values()[i])
		player.lose_item(item_in_decompose)
		item_in_decompose = null
		update_decompose()
		decompose_button.disabled = true

func _on_craft_mouse_entered():
	hover_craft_button = true
	update_components()

func _on_craft_mouse_exited():
	hover_craft_button = false
	update_components()
