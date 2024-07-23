extends Control

const MAP_SIZE = Vector2(200.0, 200.0)
var category_selected := 0
var item_workshop_selected : Item

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_hud = preload("res://Scenes/UI/ItemHud.tscn")
var pre_ability_hud = preload("res://Scenes/UI/AbilityHud.tscn")
var pre_item_workshop_list = preload("res://Scenes/UI/ItemWorkshopList.tscn")
var pre_stat_hud = preload("res://Scenes/UI/StatHud.tscn")
var pre_xp_gem_hud = preload("res://Scenes/UI/ExperienceGem.tscn")
var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

var stats_icons = [preload("res://Assets/2D/UI/stat_physical.png"), \
preload("res://Assets/2D/UI/stat_magic.png"), \
preload("res://Assets/2D/UI/stat_armor_physical.png"), \
preload("res://Assets/2D/UI/stat_armor_magic.png"), \
preload("res://Assets/2D/UI/stat_movement_speed.png"), \
preload("res://Assets/2D/UI/stat_souls.png"), \
preload("res://Assets/2D/UI/stat_cdr.png"), \
preload("res://Assets/2D/UI/stat_health_regen.png"), \
preload("res://Assets/2D/UI/stat_max_health.png"), \
preload("res://Assets/2D/UI/stat_life_steal.png")]

@onready var player := get_node("..").get_node("..")
@onready var scoreboard := $ScoreBoard
@onready var chat := $Chat
@onready var component_list := $Components/Pad/CompList
@onready var item_list = $Items/Pad/ItemList
@onready var ability_list = $ActionPanel/AbilityBar/Pad/AbilityList
@onready var stats_list = $Stats/MarginContainer/StatList
@onready var channeling_bar := $ChannelingBar
@onready var mini_map := $MiniMap
@onready var workshop := $Workshop
@onready var workshop_item_list := $Workshop/ItemBoard/ItemListContainer/Pad/ItemList
@onready var workshop_item_inspection_icon := $Workshop/ViewAndMake/Inspector/ItemView
@onready var workshop_item_inspection_name := $Workshop/ViewAndMake/Inspector/ItemName
@onready var workshop_item_inspection_desc := $Workshop/ViewAndMake/Inspector/ItemDesc
@onready var workshop_item_inspection_comps := $Workshop/ViewAndMake/Inspector/ComponentsNeeded
@onready var workshop_item_craft_button := $Workshop/ViewAndMake/Inspector/CraftItem
@onready var health_bar_hud := $ActionPanel/BarContainer/Pad/HealthBar
@onready var experience_gem_container := $Pad/ExpContainer
@onready var level_label_hud := $LevelPan/LevelInd

func _process(_delta):
	mini_map.update_camera_position(player.camera.global_position, player.camera_base_marker.position)
	mini_map.update_player_position(player.global_position)

func update_map_data(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, interests_data : PackedVector2Array) -> void:
	mini_map.initialize_minimap(MAP_SIZE, paths_data, bases_data, interests_data)
	initialize_fog_map(bases_data)

func update_info_bars() -> void:
	player.health_bar.value = float(player.health) / float(player.max_health) * 100.0
	player.level_label.text = str(player.level)
	health_bar_hud.value = float(player.health) / float(player.max_health) * 100.0
	level_label_hud.text = str(player.level)
	
	for i in experience_gem_container.get_children():
		i.free()
	
	for i in range(player.max_experience):
		var new_xp_gem = pre_xp_gem_hud.instantiate()
		new_xp_gem.material.set_shader_parameter("filled", player.experience > i)
		experience_gem_container.add_child(new_xp_gem)

var fog_map : Image
var density_tex : ImageTexture3D
const FOG_RESOLUTION = 1
const FOG_TEXTURE_SIZE = Vector2i(int(MAP_SIZE.x), int(MAP_SIZE.y)) * FOG_RESOLUTION
const FOG_PLAYER_SIZE = Vector2i(15, 15) * FOG_RESOLUTION
const FOG_BASE_SIZE = Vector2i(24, 24) * FOG_RESOLUTION
func initialize_fog_map(bases_data : PackedVector2Array) -> void:
	fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	fog_map.fill(Color(1.0, 1.0, 1.0))
	density_tex = ImageTexture3D.new()
	density_tex.create(Image.FORMAT_RGBA8, FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, 1, false, [fog_map])
	mini_map.initialize_fog(bases_data, FOG_BASE_SIZE, FOG_PLAYER_SIZE, FOG_TEXTURE_SIZE)
	update_map_fog()

func update_map_fog() -> void:
	var _fog_position = world_to_fog_position(Vector2(player.global_position.x, player.global_position.z))
	var _player_img = pre_circle_image.duplicate()
	_player_img.resize(FOG_PLAYER_SIZE.x, FOG_PLAYER_SIZE.y, Image.INTERPOLATE_NEAREST)
	fog_map.blend_rect(_player_img, _player_img.get_used_rect(), _fog_position - _player_img.get_size()/2)
	mini_map.update_fog(fog_map, FOG_PLAYER_SIZE, player.global_position)
	density_tex.update([fog_map])
	player.world.fog_of_war.material.set("density_texture", density_tex)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_close_workshop_pressed() -> void:
	workshop.set_visible(false)

#func _on_update_movement_line_timeout() -> void: #MINILAG
	#if nav.target_position == Vector3(0.0, 0.0, 0.0):
		#nav.target_position = player.global_position
	#nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)
	#update_map_fog()

func _on_craft_item_pressed():
	if player.in_workshop:
		for c in range(item_workshop_selected.craft_recipe.size()):
			player.lose_component(item_workshop_selected.craft_recipe.keys()[c], item_workshop_selected.craft_recipe.values()[c])
			
			#if item_workshop_selected.craft_recipe.values()[c] == player.components.get(item_workshop_selected.craft_recipe.keys()[c]):
				#player.components.erase(item_workshop_selected.craft_recipe.keys()[c])
			#else:
				#var _new_quantity = player.components.get(item_workshop_selected.craft_recipe.keys()[c]) - item_workshop_selected.craft_recipe.values()[c]
				#var _new_components = {item_workshop_selected.craft_recipe.keys()[c]:_new_quantity}
				#player.components.merge(_new_components, true)
		update_workshop_inspection_tab(item_workshop_selected)

func select_item(item : Item) -> void:
	item_workshop_selected = item
	update_workshop_inspection_tab(item)

func update_workshop_item_list(category : int) -> void:
	for i in workshop_item_list.get_children():
		i.queue_free()
	match category:
		0:
			for i in range(all_item_base.base.size()):
				var _new_item = pre_item_workshop_list.instantiate()
				_new_item.item = all_item_base.base[i]
				workshop_item_list.add_child(_new_item)
				_new_item.select_item.connect(Callable(self, "select_item"))

func update_workshop_inspection_tab(item : Item) -> void:
	for i in workshop_item_inspection_comps.get_children():
		i.queue_free()
	if item:
		workshop_item_inspection_icon.texture = item.icon
		workshop_item_inspection_name.text = item.name
		workshop_item_inspection_desc.text = item.description
		workshop_item_craft_button.disabled = !player.is_item_craftable(item, player.components) or player.items.has(item)
		for c in range(item.craft_recipe.size()):
			var _new_comps_needed = pre_component_hud.instantiate()
			_new_comps_needed.component = item.craft_recipe.keys()[c]
			_new_comps_needed.quantity = item.craft_recipe.values()[c]
			workshop_item_inspection_comps.add_child(_new_comps_needed)
	else:
		workshop_item_inspection_icon.texture = null
		workshop_item_inspection_name.text = ""
		workshop_item_inspection_desc.text = ""
		workshop_item_craft_button.disabled = true

func update_abilities() -> void:
	# Clear ability bar
	for a_slot in ability_list.get_children():
		a_slot.queue_free()
	
	# Update abilities array
	var _abilities_had = []
	var _item_link = Dictionary()
	for i in player.items:
		for a in i.abilities:
			_abilities_had.append(a)
			_item_link.merge({a : i})
	
	# Allow bindings of abilities
	for a in _abilities_had:
		if player.abilities.has(a):
			continue
		player.abilities[player.abilities.find(null)] = a
	for a in player.abilities:
		if !_abilities_had.has(a):
			player.abilities[player.abilities.find(a)] = null
			#Si il y a trop de sort pour l'instant ça va faire de la merde
	
	# Populate ability bar
	for a in range(player.abilities.size()):
		var _new_ability_hud = pre_ability_hud.instantiate()
		if player.abilities[a]:
			if player.abilities_machine.get_ability_cooldown(player.abilities[a]):
				_new_ability_hud.cooldown_left = player.abilities_machine.get_ability_cooldown(player.abilities[a])
			_new_ability_hud.ability = player.abilities[a]
			_new_ability_hud.item = _item_link.get(player.abilities[a])
		for i in InputMap.get_actions():
			if i.begins_with("ability") and i.ends_with(str(a+1)):
				_new_ability_hud.keybind = InputMap.action_get_events(i)[0].as_text()
		_new_ability_hud.connect("drag_ability", Callable(self, "drag_ability"))
		_new_ability_hud.connect("drop_ability", Callable(self, "drop_ability"))
		ability_list.add_child(_new_ability_hud)

func update_items() -> void:
	for i in item_list.get_children():
		i.queue_free()
	for i in player.items:
		var _new_item_hud = pre_item_hud.instantiate()
		_new_item_hud.item = i
		_new_item_hud.connect("drag_drop_item", Callable(player, "drop_item"))
		item_list.add_child(_new_item_hud)

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(player.components.size()):
		var _new_component_hud = pre_component_hud.instantiate()
		_new_component_hud.component = player.components.keys()[i]
		_new_component_hud.quantity = player.components.values()[i]
		component_list.add_child(_new_component_hud)

func update_stats_hud() -> void:
	var _stats = [player.physical_damage, player.magic_damage, player.physical_armor, \
	player.magic_armor, player.movement_speed, player.souls, player.cooldown_reduction, \
	player.health_regeneration, player.max_health, player.life_steal]
	
	for i in stats_list.get_children():
		i.queue_free()
	
	for i in range(_stats.size()):
		var _new_stat_hud = pre_stat_hud.instantiate()
		_new_stat_hud.stat = str(_stats[i])
		_new_stat_hud.icon = stats_icons[i]
		stats_list.add_child(_new_stat_hud)

var dragged_slot : Object
func drag_ability(slot : Object) -> void:
	dragged_slot = slot

func drop_ability(slot : Object) -> void:
	if dragged_slot:
		var _temp_ability = slot.ability
		player.abilities[ability_list.get_children().find(slot)] = dragged_slot.ability
		player.abilities[ability_list.get_children().find(dragged_slot)] = _temp_ability
		update_abilities()
		dragged_slot = null
