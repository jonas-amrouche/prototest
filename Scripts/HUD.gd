extends Control

@onready var player := get_parent().get_parent()
@onready var world = player.get_parent()
@onready var scoreboard := $ScoreBoard
@onready var chat := $Chat
@onready var target_tab := $TargetData
@onready var target_name := $TargetData/TargCont/Pad/Pad/EntityName
@onready var target_icon := $TargetData/TargCont/Pad/EntityIcon
@onready var target_health := $TargetData/TargCont/Pad/Pad/Pad/HealthBar
@onready var target_inventory_list := $TargetData/TargCont/Items
@onready var craft_tab := $ItemCraft
@onready var craft_result_container := $ItemCraft/Pad/CraftResult
@onready var craft_list := $ItemCraft/Pad/CraftList
@onready var craft_bar := $ItemCraft/ProgressPad/CraftBar
@onready var inventory_list = $Inventory/Container/InventoryList
@onready var consumables_list = $Inventory/Container/ConsumableList
@onready var ability_list = $ActionPanel/AbilityBar/Pad/AbilityList
#@onready var non_binded_abilities_tab = $NonBindedAbilities
#@onready var non_binded_abilities_list = $NonBindedAbilities/Container/Pad/AbilitiesList
@onready var stats_list = $Stats/MarginContainer/StatList
@onready var channeling_bar := $ChannelingBar
@onready var channeling_label := $ChannelingBar/ChannelingLabel
@onready var souls_label := $Souls/SoulsLabel
@onready var mini_map := $MiniMap
@onready var health_bar := $ActionPanel/HealthBarContainer/HealthBar
@onready var health_label := $ActionPanel/HealthBarContainer/HealthLabel
@onready var xp_bar := $ExpBar
@onready var effect_container := $EffectPad/EffectContainer
@onready var level_label_hud := $ActionPanel/LevelInd
@onready var workshop_tab := $Workshop
@onready var workshop_items_container := $Workshop/ItemBoard/WindowCont/SearchPad/Pad/ItemScrollCont/ItemList
@onready var loot_tab := $Loot
@onready var loot_container := $Loot/Container/LootList

var item_preview
#var component_preview
var effect_preview
var ability_preview
var bind_ability_preview

var dragged_ability_slot : Object
var dragged_item_ref : Object

func _process(_delta):
	mini_map.update_camera_position(player.camera.global_position, player.camera_base_marker.position)
	mini_map.update_player_position(player.global_position)
	update_previews()

func update_info_bars() -> void:
	player.health_bar.value = float(player.entity.health) / float(player.entity.max_health) * 100.0
	#player.level_label.text = str(player.level)
	health_bar.value = float(player.entity.health) / float(player.entity.max_health) * 100.0
	health_label.text = str(player.entity.health) + "/" + str(int(player.entity.max_health))
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

func bind_default_abilities() -> void:
	for i in range(player.abilities.size()):
		if player.abilities[i].id == "direct_slash":
			player.abilities[i].slot_id = 0
		if player.abilities[i].id == "cutting_around":
			player.abilities[i].slot_id = 10
	update_abilities()

func bind_ability_to_empty_slot(ab : Ability) -> void:
	var _slot_taken : PackedInt32Array
	for i in range(player.abilities.size()):
		_slot_taken.append(player.abilities[i].slot_id)
	
	if !(10 in _slot_taken) and ab.targeted:
		bind_ability_to(ab, 10)
	
	for i in range(10):
		if i in _slot_taken:
			continue
		bind_ability_to(player.abilities[player.abilities.find(ab)], i)
		update_abilities()
		return

## Bind ability to a slot_id, swap it, if one already there
func bind_ability_to(ab : Ability, id : int) -> void:
	var ability_to_swap : Ability
	for i in range(player.abilities.size()):
		if player.abilities[i].slot_id == id:
			ability_to_swap = player.abilities[i]
			break
	if ability_to_swap:
		ability_to_swap.slot_id = ab.slot_id
	ab.slot_id = id

var craft_tween : Tween
func update_craft() -> void:
	for i in craft_list.get_children():
		i.queue_free()
	
	if craft_tween:
		craft_tween.kill()
		craft_bar.value = 0.0
	
	if player.crafts[0].item and player.crafts[1].item and !player.crafts[2].item:
		craft_tween = get_tree().create_tween()
		craft_tween.tween_property(craft_bar, "value", 100.0, Basics.CRAFT_TIME)
		craft_tween.finished.connect(func():
			craft_bar.value = 0.0
			player.craft_item())
	for i in range(player.crafts.size()):
		var _new_item_slot = world.resources.item_hud.instantiate()
		_new_item_slot.connect("drop_item", Callable(self, "drop_item_craft"))
		_new_item_slot.connect("drag_item", Callable(self, "drag_item"))
		_new_item_slot.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_slot.connect("mouse_exited", Callable(self, "hide_item_preview"))
		_new_item_slot.item_slot = player.crafts[i]
		_new_item_slot.available = player.in_base
		if i == 2 and !player.crafts[2].item:
			_new_item_slot.available = false
		craft_list.add_child(_new_item_slot)

var loot_times : int
func open_and_display_loot(loot : Array[ItemSlot]) -> void:
	for l in loot_container.get_children():
		l.queue_free()
	
	loot_tab.show()
	
	for l in loot:
		var _new_item_hud = world.resources.item_hud.instantiate()
		_new_item_hud.item_slot = l
		_new_item_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		loot_container.add_child(_new_item_hud)
	
	loot_times += 1
	get_tree().create_timer(2.0).timeout.connect(func():
		loot_times -= 1
		if loot_times == 0:
			loot_tab.hide())

func update_target() -> void:
	target_tab.set_visible(player.selected_target != null)
	if player.selected_target:
		target_name.set_text(player.selected_target.entity.id.capitalize())
		if player.selected_target.entity.icon:
			target_icon.set_texture(player.selected_target.entity.icon)
		match player.selected_target.entity.entity_type:
			Basics.EntityType.MONSTER, Basics.EntityType.PLAYER, Basics.EntityType.GUARDS:
				target_health.set_value(float(player.selected_target.entity.health) / float(player.selected_target.entity.max_health) * 100.0)

func update_abilities() -> void:
	# Clear ability bars
	#for a_slot in non_binded_abilities_list.get_children():
		#a_slot.queue_free()
	for a_slot in ability_list.get_children():
		a_slot.queue_free()
	
	# Get item data
	var _abilities_had = []
	var _item_link = Dictionary()
	for i in player.inventory:
		if !i.item: continue
		for a in i.item.abilities:
			_abilities_had.append(a)
			_item_link.merge({a : i.item})
	
	# Update player abilities array
	# Gather all abilities from items and add them to player if not yet added
	for a in _abilities_had:
		if player.abilities.has(a):
			continue
		a.slot_id = -1
		player.abilities.append(a)
	
	# Remove all abilities that should not be in player ability array anymore
	for a in player.abilities:
		if !_abilities_had.has(a): # TODO : VERIFY if this work (cant verify now because no way of losing an item)
			player.abilities.erase(a)
	
	# Sort abilities in an array for ability_hud spawning
	var _sorted_ability_bar : Array[Ability]
	for a in range(11):
		for aa in range(player.abilities.size()):
			if player.abilities[aa].slot_id == a:
				_sorted_ability_bar.append(player.abilities[aa])
				break
		if _sorted_ability_bar.size() != a+1:
			_sorted_ability_bar.append(null)
	
	# Populate ability bar
	for a in range(_sorted_ability_bar.size()):
		var _new_ability_hud = world.resources.ability_hud.instantiate()
		if _sorted_ability_bar[a]:
			if player.ability_machine.get_ability_cooldown(_sorted_ability_bar[a]):
				_new_ability_hud.cooldown_left = player.ability_machine.get_ability_cooldown(_sorted_ability_bar[a])
			_new_ability_hud.ability = _sorted_ability_bar[a]
			_new_ability_hud.item = _item_link.get(_sorted_ability_bar[a])
		
		if a == 10:
			_new_ability_hud.is_auto_attack = true
		else:
			for i in InputMap.get_actions():
				if i.begins_with("ability") and i.ends_with(str(a+1)):
					_new_ability_hud.keybind = InputMap.action_get_events(i)[0].as_text()
		_new_ability_hud.connect("drag_ability", Callable(self, "drag_ability"))
		_new_ability_hud.connect("drop_ability", Callable(self, "drop_ability"))
		_new_ability_hud.connect("mouse_entered_ability", Callable(self, "show_ability_preview"))
		_new_ability_hud.connect("mouse_exited", Callable(self, "hide_ability_preview"))
		_new_ability_hud.connect("assign_auto_attack", Callable(self, "assign_auto_attack"))
		_new_ability_hud.connect("unbind", Callable(self, "unbind_ability"))
		
		ability_list.add_child(_new_ability_hud)
	
	# Populate nonbinded bar
	#non_binded_abilities_tab.hide()
	#for a in range(player.abilities.size()):
		#if player.abilities[a].slot_id != -1:
			#continue
		#non_binded_abilities_tab.show()
		#var _new_ability_hud = world.resources.ability_hud.instantiate()
		#_new_ability_hud.custom_minimum_size = Vector2(37.0, 37.0)
		#if player.abilities[a]:
			#if player.ability_machine.get_ability_cooldown(player.abilities[a]):
				#_new_ability_hud.cooldown_left = player.ability_machine.get_ability_cooldown(player.abilities[a])
			#_new_ability_hud.ability = player.abilities[a]
			#_new_ability_hud.item = _item_link.get(player.abilities[a])
		#
		#_new_ability_hud.connect("drag_ability", Callable(self, "drag_ability"))
		#_new_ability_hud.connect("drop_ability", Callable(self, "drop_ability"))
		#_new_ability_hud.connect("mouse_entered_ability", Callable(self, "show_ability_preview"))
		#_new_ability_hud.connect("mouse_exited", Callable(self, "hide_ability_preview"))
		
		#non_binded_abilities_list.add_child(_new_ability_hud)

func update_inventory() -> void:
	for i in inventory_list.get_children():
		i.queue_free()
	for i in consumables_list.get_children():
		i.queue_free()
	
	# Populate item bar
	for i in range(player.inventory.size()):
		var _new_item_hud = world.resources.item_hud.instantiate()
		_new_item_hud.item_slot = player.inventory[i]
		_new_item_hud.connect("drop_item", Callable(self, "drop_item"))
		_new_item_hud.connect("drag_item", Callable(self, "drag_item"))
		_new_item_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		_new_item_hud.connect("show_abilities", Callable(self, "show_bind_abilities"))
		if i >= player.inventory_size:
			_new_item_hud.available = false
		inventory_list.add_child(_new_item_hud)
	
	# Populate consumables bar
	for c in range(player.consumables.size()):
		var _new_item_hud = world.resources.item_hud.instantiate()
		_new_item_hud.item_slot = player.consumables[c]
		_new_item_hud.connect("drop_item", Callable(self, "drop_item"))
		_new_item_hud.connect("drag_item", Callable(self, "drag_item"))
		_new_item_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_item_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		for k in InputMap.get_actions():
			if k.begins_with("consumable") and k.ends_with(str(c+1)):
				_new_item_hud.keybind = InputMap.action_get_events(k)[0].as_text()
		if c >= player.consumables_size:
			_new_item_hud.available = false
		consumables_list.add_child(_new_item_hud)

func show_item_preview(item : Item) -> void:
	if item_preview:
		item_preview.queue_free()
	if item:
		item_preview = world.resources.item_preview.instantiate()
		item_preview.hide()
		item_preview.item = item
		add_child(item_preview)

func hide_item_preview() -> void:
	if item_preview:
		item_preview.queue_free()
		item_preview = null

func hide_bind_abilities() -> void: # TODO A APPELER QUELQUE PART
	if bind_ability_preview:
		bind_ability_preview.queue_free()
		bind_ability_preview = null

func show_bind_abilities(itm : Item, item_ref : Object) -> void:
	hide_bind_abilities()
	bind_ability_preview = world.resources.bind_ability_hud.instantiate()
	bind_ability_preview.item = itm
	bind_ability_preview.hud = self
	add_child(bind_ability_preview)
	
	var _position_offset = Vector2(bind_ability_preview.size.x/2.0 - item_ref.size.x/2.0, bind_ability_preview.size.y + 10.0)
	bind_ability_preview.position = item_ref.global_position - _position_offset

func show_ability_preview(ability_ref : Object) -> void:
	if ability_ref.ability:
		ability_preview = world.resources.ability_preview.instantiate()
		ability_preview.ability = ability_ref.ability
		ability_preview.item = ability_ref.item
		add_child(ability_preview)
		var _position_offset = Vector2(ability_preview.size.x/2.0 - ability_ref.size.x/2.0, ability_preview.size.y + 10.0)
		
		# For abilities in the binded abilities list (avoid preview from going outside the screen)
		if ability_ref.custom_minimum_size.x != 55.0: 
			_position_offset = Vector2(ability_ref.size.x, ability_preview.size.y + 10.0)
		
		ability_preview.position = ability_ref.global_position - _position_offset

func hide_ability_preview() -> void:
	if ability_preview:
		ability_preview.queue_free()
		ability_preview = null

func assign_auto_attack(ability_ref : Object) -> void:
	bind_ability_to(ability_ref.ability, 10)
	update_abilities()

func unbind_ability(ability_ref : Object) -> void:
	ability_ref.ability.slot_id = -1
	update_abilities()

func update_effects() -> void:
	for i in effect_container.get_children():
		i.queue_free()
	for i in range(player.effect_machine.active_effects.size()):
		var _new_effect_hud = world.resources.effect_hud.instantiate()
		_new_effect_hud.effect = player.effect_machine.active_effects.keys()[i]
		_new_effect_hud.connect("mouse_entered_effect", Callable(self, "show_effect_preview"))
		_new_effect_hud.connect("mouse_exited", Callable(self, "hide_effect_preview"))
		effect_container.add_child(_new_effect_hud)

func show_effect_preview(effect : Effect) -> void:
	if effect_preview:
		effect_preview.queue_free()
	if effect:
		effect_preview = world.resources.effect_preview.instantiate()
		effect_preview.effect = effect
		add_child(effect_preview)

func hide_effect_preview() -> void:
	if effect_preview:
		effect_preview.queue_free()
		effect_preview = null

func update_previews() -> void:
	if effect_preview:
		effect_preview.position = get_viewport().get_mouse_position() - Vector2(effect_preview.size.x, effect_preview.size.y)
	if item_preview:
		item_preview.position = get_viewport().get_mouse_position() - Vector2(0.0, item_preview.size.y)

func update_stats_hud() -> void:
	for i in stats_list.get_children():
		i.queue_free()
	
	var stat_base = Basics.get_all_stats()
	var _p_entity : Entity = player.entity
	
	spawn_stat(stat_base["physical_damage"], _p_entity.physical_damage)
	spawn_stat(stat_base["magic_damage"], _p_entity.magic_damage)
	spawn_stat(stat_base["physical_armor"], _p_entity.physical_armor)
	spawn_stat(stat_base["magic_armor"], _p_entity.magic_armor)
	spawn_stat(stat_base["movement_speed"], _p_entity.movement_speed)
	spawn_stat(stat_base["cooldown_reduction"], _p_entity.cooldown_reduction)
	spawn_stat(stat_base["max_health"], _p_entity.max_health)
	spawn_stat(stat_base["health_regeneration"], _p_entity.health_regeneration)
	spawn_stat(stat_base["life_steal"], _p_entity.life_steal)
	spawn_stat(stat_base["souls"], _p_entity.souls)

func spawn_stat(stat : Stat, value) -> void:
	var _new_stat_hud = world.resources.stat_hud.instantiate()
	_new_stat_hud.stat_value = value
	_new_stat_hud.stat = stat
	stats_list.add_child(_new_stat_hud)

func update_workshop() -> void:
	for i in workshop_items_container.get_children():
		i.queue_free()
	
	for i in Basics.get_all_items():
		#if i.craft.size() > 0:
		var _new_recipe_hud = world.resources.item_workshop_scene.instantiate()
		_new_recipe_hud.item = i
		_new_recipe_hud.connect("mouse_entered_item", Callable(self, "show_item_preview"))
		_new_recipe_hud.connect("mouse_exited", Callable(self, "hide_item_preview"))
		workshop_items_container.add_child(_new_recipe_hud)

func drag_ability(slot : Object) -> void:
	dragged_ability_slot = slot

func drop_ability(slot : Object) -> void:
	if dragged_ability_slot:
		if slot.ability:
			var _temp_dragged_slot_id = dragged_ability_slot.ability.slot_id
			player.abilities[player.abilities.find(dragged_ability_slot.ability)].slot_id = slot.ability.slot_id
			player.abilities[player.abilities.find(slot.ability)].slot_id = _temp_dragged_slot_id
		else:
			player.abilities[player.abilities.find(dragged_ability_slot.ability)].slot_id = ability_list.get_children().find(slot)
		update_abilities()
		dragged_ability_slot = null

func drag_item(slot : Object) -> void:
	if Input.is_action_pressed("quick_item_move"):
		if slot.item_slot.item:
			if slot.item_slot.slot_type == Basics.SlotType.CRAFT:
				# Quick move from craft or consummables to inventory
				player.obtain_item(slot.item_slot.item, slot.item_slot.quantity)
				slot.item_slot.item = null
				slot.item_slot.quantity = 0
				update_craft()
			else:
				# Quick move from inventory or consummables to craft
				if (!player.crafts[0].item or !player.crafts[1].item) and player.in_base:
					var _empty_slot = player.get_empty_slot(player.crafts)
					_empty_slot.item = slot.item_slot.item
					_empty_slot.quantity = 1
					player.lose_item(slot.item_slot.item, 1)
					update_craft()
			player.update_items()
			return
	else:
		dragged_item_ref = slot

func drop_item(slot : Object) -> void:
	if dragged_item_ref and dragged_item_ref.item_slot.item:
		
		# Droped from a craft cell to inventory or consummables
		if dragged_item_ref.item_slot.slot_type == Basics.SlotType.CRAFT: # verif l'item draged est bien du même type que le slot
			if player.get_item_source(dragged_item_ref.item_slot.item) == player.get_item_slot_source(slot.item_slot):
				if player.has_item(dragged_item_ref.item_slot.item, player.get_item_source(dragged_item_ref.item_slot.item)):
					var _drop_slot = player.get_item_slot(dragged_item_ref.item_slot.item, player.get_item_source(dragged_item_ref.item_slot.item))
					_drop_slot.quantity += dragged_item_ref.item_slot.quantity
					dragged_item_ref.item_slot.item = null
					dragged_item_ref.item_slot.quantity = 0
				else:
					var _drag_slot = dragged_item_ref.item_slot.duplicate()
					dragged_item_ref.item_slot.item = slot.item_slot.item
					dragged_item_ref.item_slot.quantity = slot.item_slot.quantity
					slot.item_slot.item = _drag_slot.item
					slot.item_slot.quantity = _drag_slot.quantity
				update_craft()
		else:
			# Droped from and to inventory or consummables
			if dragged_item_ref.item_slot.slot_type == slot.item_slot.slot_type:
				var _dragged_slot_id = dragged_item_ref.item_slot.slot_id
				dragged_item_ref.item_slot.slot_id = slot.item_slot.slot_id
				slot.item_slot.slot_id = _dragged_slot_id
		
		player.update_items()
		update_abilities()
		
		dragged_item_ref = null

func drop_item_craft(slot : Object) -> void:
	if dragged_item_ref and slot != dragged_item_ref and player.in_base:
		# Droped from a craft cell to a craft cell
		if dragged_item_ref.item_slot.slot_type == Basics.SlotType.CRAFT:
			var _slot_item = slot.item_slot.duplicate()
			slot.item_slot.item = dragged_item_ref.item_slot.item
			dragged_item_ref.item_slot.item = _slot_item.item
		else:
			# Droped from a inventory cell to a craft cell
			if dragged_item_ref.item_slot.quantity > 1 and !slot.item_slot.item:
				dragged_item_ref.item_slot.quantity -= 1
				slot.item_slot.item = dragged_item_ref.item_slot.item
				slot.item_slot.quantity = 1
			else:
				var _slot_item = slot.item_slot.duplicate()
				slot.item_slot.item = dragged_item_ref.item_slot.item
				dragged_item_ref.item_slot.item = _slot_item.item
				#player.inventory[dragged_item_ref.item_slot.item.id] = slot.item_slot
		player.update_items()
		update_abilities()
		update_craft()
		dragged_item_ref = null

func _on_close_workshop_pressed() -> void:
	workshop_tab.hide()
