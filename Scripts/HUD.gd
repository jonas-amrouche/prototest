extends Control

#var category_selected := 0
#var item_craft_selected : Item
#var hover_craft_button : bool
var item_in_craft : Array[ItemSlot] = [null, null, null]
var auto_attack_id := 0

const CRAFT_TIME = 2.0

var pre_component_hud = preload("res://Scenes/UI/component_hud.tscn")
var pre_item_hud = preload("res://Scenes/UI/item_hud.tscn")
var pre_ability_hud = preload("res://Scenes/UI/ability_hud.tscn")
var pre_item_craft = preload("res://Scenes/UI/item_craft.tscn")
var pre_stat_hud = preload("res://Scenes/UI/stat_hud.tscn")
#var pre_xp_gem_hud = preload("res://Scenes/UI/experience_gem.tscn")
var pre_effect_hud = preload("res://Scenes/UI/effect_hud.tscn")
var pre_item_preview = preload("res://Scenes/UI/item_preview.tscn")
var pre_ability_preview = preload("res://Scenes/UI/ability_preview.tscn")
var pre_component_preview = preload("res://Scenes/UI/component_preview.tscn")
var pre_effect_preview = preload("res://Scenes/UI/effect_preview.tscn")

#var all_item_base = preload("res://Resources/ItemBases/AllItems.tres")

@onready var player := get_node("..").get_node("..")
@onready var scoreboard := $ScoreBoard
@onready var chat := $Chat
@onready var craft_tab := $ItemCraft
@onready var craft_result_container := $ItemCraft/Pad/CraftResult
@onready var craft_comps_container := $ItemCraft/Pad/CraftComps
@onready var craft_bar := $ItemCraft/ProgressPad/CraftBar
@onready var inventory_list = $Inventory/Pad/InventoryList
@onready var ability_list = $ActionPanel/AbilityBar/Pad/AbilityList
@onready var stats_list = $Stats/MarginContainer/StatList
@onready var channeling_bar := $ChannelingBar
@onready var channeling_label := $ChannelingBar/ChannelingLabel
@onready var souls_label := $Souls/SoulsLabel
@onready var mini_map := $MiniMap
@onready var health_bar := $ActionPanel/BarContainer/Pad/HealthBar
@onready var xp_bar := $ExpBar
@onready var effect_container := $EffectPad/EffectContainer
@onready var level_label_hud := $ActionPanel/LevelInd

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
	player.health_label.text = str(player.health) + "/" + str(int(player.stats.max_health))
	player.level_label.text = str(player.level)
	health_bar.value = float(player.health) / float(player.stats.max_health) * 100.0
	level_label_hud.text = str(player.level)
	
	xp_bar.value = float(player.experience) / float(player.max_experience) * 100.0
	
	#for i in experience_gem_container.get_children():
		#i.free()
	#
	#for i in range(16):
		#var new_xp_gem = pre_xp_gem_hud.instantiate()
		#new_xp_gem.material.set_shader_parameter("enabled", i < player.max_experience)
		#new_xp_gem.material.set_shader_parameter("filled", player.experience > i)
		#experience_gem_container.add_child(new_xp_gem)

#func select_item(item : Item) -> void:
	#item_craft_selected = item
	#item_craft_button.disabled = !player.is_item_craftable(item) or player.items.has(item)
	#for i in craft_available_container.get_children():
		#if i.item == item:
			#continue
		#i.unselect_item()

func add_item_in_craft(item_slot : ItemSlot, craft_slot : int) -> void:
	if item_in_craft[craft_slot]:
		player.obtain_item(item_in_craft[craft_slot].item)
	player.lose_item(item_slot.item, item_slot.quantity)
	item_in_craft[craft_slot] = item_slot
	update_craft()

var craft_tween : Tween
func update_craft() -> void:
	for i in craft_comps_container.get_children():
		i.queue_free()
	
	if craft_tween:
		craft_tween.kill()
		craft_bar.value = 0.0
	
	if item_in_craft[0] and item_in_craft[1]:
		craft_tween = get_tree().create_tween()
		craft_tween.tween_property(craft_bar, "value", 100.0, CRAFT_TIME)
		craft_tween.finished.connect(craft_item)
	
	for i in range(3):
		var _new_item_slot = pre_item_hud.instantiate()
		_new_item_slot.connect("drop_item", Callable(self, "drop_item_craft_"+str(i+1)))
		_new_item_slot.connect("drag_item", Callable(self, "drag_item"))
		_new_item_slot.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_slot.connect("mouse_exited", Callable(self, "hide_item_preview"))
		if item_in_craft[i]:
			_new_item_slot.item_slot = item_in_craft[i]
		elif i == 2 and !item_in_craft[2]:
			_new_item_slot.available = false
		#_new_item_slot.available = player.in_base
		craft_comps_container.add_child(_new_item_slot)

func get_all_items() -> Array[Item]:
	var _item_base: Array[Item] = []
	var _path = "res://Resources/Items/"
	var _dir = DirAccess.open(_path)
	_dir.list_dir_begin()
	var _file_name = _dir.get_next()
	while _file_name != "":
		var _file_path = _path + "/" + _file_name
		if !_dir.current_is_dir():
			_item_base.append(load(_file_path))
		_file_name = _dir.get_next()
	return _item_base

func craft_item() -> void:
	if item_in_craft[0] and item_in_craft[1]:
		craft_bar.value = 0.0
		
		# If craft success the item
		for i in get_all_items():
			var _craft_comp : Array[Item] = [item_in_craft[0].item, item_in_craft[1].item]
			if player.is_item_craftable(i, _craft_comp):
				var _new_item_slot = ItemSlot.new()
				_new_item_slot.item = i
				_new_item_slot.quantity = 1
				item_in_craft[2] = _new_item_slot
				item_in_craft[0] = null
				item_in_craft[1] = null
				break
		
		# If craft failed destroy all items
		if !item_in_craft[2]:
			for i in range(item_in_craft.size()):
				item_in_craft[i] = null
		
		update_craft()

# Used to clear the craft tab when exiting the base
func clear_craft() -> void:
	for i in range(item_in_craft.size()):
		if item_in_craft[i]:
			if player.is_inventory_full():
				print("ALED") # TODO FIX THIS
				return
			player.obtain_item(item_in_craft[i].item, item_in_craft[i].quantity)
			item_in_craft[i] = null
	update_craft()

#func update_craft_available() -> void:
	#item_craft_selected = null
	#item_craft_button.disabled = true
	#for i in craft_available_container.get_children():
		#i.queue_free()
	#
	#for i in all_item_base.base:
		#if player.is_item_craftable(i):
			#var _new_item_craft = pre_item_craft.instantiate()
			#_new_item_craft.item = i
			#_new_item_craft.select_item.connect(Callable(self, "select_item"))
			#_new_item_craft.connect("mouse_entered_item", Callable(self, "show_item_preview"))
			#_new_item_craft.connect("mouse_exited", Callable(self, "hide_item_preview"))
			#craft_available_container.add_child(_new_item_craft)
	#
	#craft_available_nothing.set_visible(craft_available_container.get_child_count() == 0)

func update_abilities() -> void:
	# Clear ability bar
	for a_slot in ability_list.get_children():
		a_slot.queue_free()
	
	# Get item data
	var _abilities_had = []
	var _item_link = Dictionary()
	for i in player.inventory:
		if i == null:
			continue
		for a in i.item.abilities:
			_abilities_had.append(a)
			_item_link.merge({a : i.item})
	
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

func update_inventory() -> void:
	# Clear item bar
	for i in inventory_list.get_children():
		i.queue_free()
	
	# Populate item bar
	for i in player.inventory:
		var _new_item_hud = pre_item_hud.instantiate()
		if i:
			_new_item_hud.item_slot = i
		_new_item_hud.connect("drop_item", Callable(self, "drop_item_inventory"))
		_new_item_hud.connect("drag_item", Callable(self, "drag_item"))
		_new_item_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		inventory_list.add_child(_new_item_hud)

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

var dragged_item_ref : Object
func drag_item(slot : Object) -> void:
	dragged_item_ref = slot

func drop_item_inventory(slot : Object) -> void:
	if dragged_item_ref:
		if item_in_craft.has(dragged_item_ref.item_slot):
			player.inventory[inventory_list.get_children().find(slot)] = dragged_item_ref.item_slot
			item_in_craft[item_in_craft.find(dragged_item_ref.item_slot)] = null
			update_inventory()
			update_abilities()
			update_craft()
			dragged_item_ref = null
			return
		player.inventory[inventory_list.get_children().find(slot)] = dragged_item_ref.item_slot
		player.inventory[inventory_list.get_children().find(dragged_item_ref)] = slot.item_slot
		update_inventory()
		dragged_item_ref = null

func drop_item_craft_1(slot : Object) -> void:
	drop_item_craft(slot, 0)
func drop_item_craft_2(slot : Object) -> void:
	drop_item_craft(slot, 1)
func drop_item_craft_3(_slot : Object) -> void:
	pass

func drop_item_craft(slot : Object, craft_slot : int) -> void:
	if dragged_item_ref and slot != dragged_item_ref:
		# Droped from a craft cell to a craft cell
		if item_in_craft.has(dragged_item_ref.item_slot):
			item_in_craft[item_in_craft.find(dragged_item_ref.item_slot)] = slot.item_slot
			item_in_craft[craft_slot] = dragged_item_ref.item_slot
		else:
		# Droped from a inventory cell to a craft cell
			if dragged_item_ref.item_slot.item.rarity == Basics.RARITY.COMPONENTS and dragged_item_ref.item_slot.quantity > 1:
				#var _inv_slot_id = player.inventory.find(dragged_item_ref.item_slot)
				dragged_item_ref.item_slot.quantity -= 1
				var _new_stack = ItemSlot.new()
				_new_stack.item = dragged_item_ref.item_slot.item
				_new_stack.quantity = 1
				_new_stack.slot_id = -1
				item_in_craft[craft_slot] = _new_stack
			else:
				item_in_craft[craft_slot] = dragged_item_ref.item_slot
				player.inventory[player.inventory.find(dragged_item_ref.item_slot)] = slot.item_slot
		update_inventory()
		update_abilities()
		update_craft()
		dragged_item_ref = null

#func _on_craft_pressed():
	#if !player.is_items_full():
		#if player.in_base:
			#for c in range(item_craft_selected.craft_recipe.size()):
				#player.lose_component(item_craft_selected.craft_recipe.keys()[c], item_craft_selected.craft_recipe.values()[c])
		#player.obtain_item(item_craft_selected)
		#item_craft_selected = null
		#item_craft_button.disabled = true
		#update_components()

#func _on_decompose_pressed():
	#if item_in_decompose:
		#for i in range(item_in_decompose.craft_recipe.size()):
			#player.obtain_component(item_in_decompose.craft_recipe.keys()[i], item_in_decompose.craft_recipe.values()[i])
		#player.lose_item(item_in_decompose)
		#item_in_decompose = null
		#update_decompose()
		#decompose_button.disabled = true
