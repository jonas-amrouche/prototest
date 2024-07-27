extends Control

const MAP_SIZE = Vector2(200.0, 200.0)
var category_selected := 0
var item_craft_selected : Item
var item_in_decompose

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_hud = preload("res://Scenes/UI/ItemHud.tscn")
var pre_ability_hud = preload("res://Scenes/UI/AbilityHud.tscn")
var pre_item_craft_list = preload("res://Scenes/UI/ItemCraftList.tscn")
var pre_stat_hud = preload("res://Scenes/UI/StatHud.tscn")
var pre_xp_gem_hud = preload("res://Scenes/UI/ExperienceGem.tscn")
var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")
var pre_item_preview = preload("res://Scenes/UI/ItemPreview.tscn")
var pre_ability_preview = preload("res://Scenes/UI/AbilityPreview.tscn")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

@onready var player := get_node("..").get_node("..")
@onready var scoreboard := $ScoreBoard
@onready var chat := $Chat
@onready var craft_tab := $CraftAvailable
@onready var craft_available_container := $CraftAvailable/Pad/Order/CraftItemPanel/CraftAvailable
@onready var craft_available_nothing := $CraftAvailable/Pad/Order/CraftItemPanel/Nothing
@onready var decompose_tab := $DecomposeItem
@onready var decompose_container := $DecomposeItem/Pad/DecomposeCont
@onready var component_list := $Components/Pad/CompList
@onready var item_list = $Items/Pad/ItemList
@onready var ability_list = $ActionPanel/AbilityBar/Pad/AbilityList
@onready var stats_list = $Stats/MarginContainer/StatList
@onready var channeling_bar := $ChannelingBar
@onready var mini_map := $MiniMap
@onready var item_craft_button := $CraftAvailable/Pad/Order/Craft
@onready var health_bar_hud := $ActionPanel/BarContainer/Pad/HealthBar
@onready var experience_gem_container := $Pad/ExpContainer
@onready var level_label_hud := $LevelPan/LevelInd

var item_preview
var ability_preview

func _process(_delta):
	mini_map.update_camera_position(player.camera.global_position, player.camera_base_marker.position)
	mini_map.update_player_position(player.global_position)

func update_map_data(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, interests_data : PackedVector2Array) -> void:
	mini_map.initialize_minimap(MAP_SIZE, paths_data, bases_data, interests_data)
	initialize_fog_map(bases_data)

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

var fog_map : Image
var density_tex : ImageTexture3D
const FOG_RESOLUTION = 2
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

func select_item(item : Item) -> void:
	item_craft_selected = item
	item_craft_button.disabled = !player.is_item_craftable(item) or player.items.has(item)

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
	_new_item_slot.connect("update_item_preview", Callable(self, "update_item_preview"))
	if item_in_decompose:
		_new_item_slot.item = item_in_decompose
	decompose_container.add_child(_new_item_slot)

func clear_decompose() -> void:
	if item_in_decompose:
		if player.items.find(null) == -1:
			_on_decompose_pressed()
			return
		player.obtain_item(item_in_decompose)
	item_in_decompose = null
	update_decompose()

func update_craft_available() -> void:
	for i in craft_available_container.get_children():
		i.queue_free()
	
	for i in all_item_base.base:
		if player.is_item_craftable(i):
			var _new_item_craft = pre_item_craft_list.instantiate()
			_new_item_craft.item = i
			_new_item_craft.select_item.connect(Callable(self, "select_item"))
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
		_new_ability_hud.connect("mouse_entered_ability", Callable(self, "show_ability_preview"))
		_new_ability_hud.connect("mouse_exited", Callable(self, "hide_ability_preview"))
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
		_new_item_hud.connect("update_item_preview", Callable(self, "update_item_preview"))
		item_list.add_child(_new_item_hud)

func show_item_preview(item : Item) -> void:
	if item:
		item_preview = pre_item_preview.instantiate()
		item_preview.hide()
		item_preview.item = item
		add_child(item_preview)

func hide_item_preview() -> void:
	if item_preview:
		item_preview.queue_free()
		item_preview = null

func update_item_preview() -> void:
	if item_preview:
		item_preview.position = get_viewport().get_mouse_position() - Vector2(0.0, item_preview.size.y)

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

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(player.components.size()):
		var _new_component_hud = pre_component_hud.instantiate()
		if player.components[i]:
			_new_component_hud.component = player.components[i]
			_new_component_hud.quantity = player.comp_quantities[i]
		_new_component_hud.connect("drag_component", Callable(self, "drag_component"))
		_new_component_hud.connect("drop_component", Callable(self, "drop_component"))
		component_list.add_child(_new_component_hud)

#func update_craft() -> void:
	#pass
	#for i in craft_list.get_children():
		#i.queue_free()
	#for i in range(player.components.size()):
		#var _new_component_hud = pre_component_hud.instantiate()
		#if player.components[i]:
			#_new_component_hud.component = player.components[i]
			#_new_component_hud.quantity = player.comp_quantities[i]
		#_new_component_hud.connect("drag_component", Callable(self, "drag_component"))
		#_new_component_hud.connect("drop_component", Callable(self, "drop_component"))
		#component_list.add_child(_new_component_hud)
	

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

func _on_craft_pressed():
	if player.in_workshop:
		for c in range(item_craft_selected.craft_recipe.size()):
			player.lose_component(item_craft_selected.craft_recipe.keys()[c], item_craft_selected.craft_recipe.values()[c])
	player.obtain_item(item_craft_selected)
	item_craft_selected = null
	item_craft_button.disabled = true

func _on_decompose_pressed():
	if item_in_decompose:
		for i in range(item_in_decompose.craft_recipe.size()):
			player.obtain_component(item_in_decompose.craft_recipe.keys()[i], item_in_decompose.craft_recipe.values()[i])
		player.lose_item(item_in_decompose)
		item_in_decompose = null
		update_decompose()
