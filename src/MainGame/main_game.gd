class_name MainGame
extends GameState

const GAME_MENU = preload("res://src/MainGame/GUI/game_menu.tscn")

@export_file("*tscn") var main_menu_scene

@onready var health_bar: Bar = %HealthBar
@onready var xp_bar: Bar = %XpBar
@onready var dungeon_floor_label: Label = %DungeonFloorLabel
@onready var character_level_label: Label = %CharacterLevelLabel
@onready var gold_label: Label = %GoldLabel
@onready var light_label: Label = %LightLabel

var _player_entity: Entity


func _ready() -> void:
	SignalBus.spawn_game_menu.connect(add_child)
	SignalBus.save.connect(_on_save)
	SignalBus.delete_save.connect(_on_delete_save)


func _on_world_map_data_set(map_data: MapData) -> void:
	var player_entity: Entity = map_data.player_entity
	var player_durability: DurabilityComponent = player_entity.get_component(Component.Type.Durability)
	health_bar.set_values(player_durability.hp, player_durability.max_hp)
	if not player_durability.hp_changed.is_connected(health_bar.set_values):
		player_durability.hp_changed.connect(health_bar.set_values)
	var player_level: LevelComponent = player_entity.get_component(Component.Type.Level)
	xp_bar.set_values(player_level.current_xp, player_level.experience_to_next_level())
	if not player_level.xp_changed.is_connected(xp_bar.set_values):
		player_level.xp_changed.connect(xp_bar.set_values)
		player_level.level_changed.connect(func(new_level: int) -> void:
			character_level_label.text = "Level %d" %new_level)
	dungeon_floor_label.text = "Dungeon Floor %d" % map_data.current_floor
	character_level_label.text = "Level %d" % player_level.current_level
	
	# Gold display
	var player_gold: GoldComponent = player_entity.get_component(Component.Type.Gold)
	if player_gold:
		gold_label.text = "Gold: %d" % player_gold.gold
		if not player_gold.gold_changed.is_connected(_on_gold_changed):
			player_gold.gold_changed.connect(_on_gold_changed)
	
	# Light duration display
	_player_entity = player_entity
	_connect_light_source_signals()
	_update_light_display()
	SignalBus.light_source_extinguished.connect(_update_light_display)


func _on_save(map_data: MapData, and_quit: bool) -> void:
	ResourceSaver.save(map_data, SAVE_PATH)
	if and_quit:
		get_tree().quit()
	else:
		transition_requested.emit(main_menu_scene)


func _on_delete_save(and_quit: bool) -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	if and_quit:
		get_tree().quit()
	else:
		transition_requested.emit(main_menu_scene)


func enter(data: Dictionary = {}) -> void:
	var map: Map = get_node("VBoxContainer/SubViewportContainer/SubViewport/World/Map")

	if data.get("load_game", false) and FileAccess.file_exists(SAVE_PATH):
		var map_data: MapData = load(SAVE_PATH)
		map.set_map_data(map_data)
		map_data.reactivate()
		Log.send_log("Hello and welcome back, to the dungeon!")
	else:
		map.generate_new_dungeon()
		Log.send_log("Hello and welcome, to yet another dungeon!")



func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "Gold: %d" % new_gold


func _connect_light_source_signals() -> void:
	if not _player_entity:
		return
	var equipment: EquipmentComponent = _player_entity.get_component(Component.Type.Equipment)
	if not equipment:
		return
	var light_item: Entity = equipment.equipped.get(EquipmentComponent.Slot.LightSource)
	if not light_item:
		return
	var light_source: LightSourceComponent = light_item.get_component(Component.Type.LightSource)
	if light_source and not light_source.duration_changed.is_connected(_on_light_duration_changed):
		light_source.duration_changed.connect(_on_light_duration_changed)


func _on_light_duration_changed(_current: int, _max: int) -> void:
	_update_light_display()


func _update_light_display() -> void:
	if not _player_entity:
		light_label.text = "Light: --"
		return
	
	var equipment: EquipmentComponent = _player_entity.get_component(Component.Type.Equipment)
	if not equipment:
		light_label.text = "Light: --"
		return
	
	var light_item: Entity = equipment.equipped.get(EquipmentComponent.Slot.LightSource)
	if not light_item:
		light_label.text = "Light: None"
		return
	
	var light_source: LightSourceComponent = light_item.get_component(Component.Type.LightSource)
	if light_source:
		if light_source.is_lit:
			light_label.text = "Light: %d/%d" % [light_source.current_duration, light_source.max_duration]
		else:
			light_label.text = "Light: BURNED OUT"
	else:
		light_label.text = "Light: --"


static func spawn_game_menu(title: String, options: Array, small_mode: bool = false) -> GameMenu:
	var game_menu: GameMenu = GAME_MENU.instantiate()
	SignalBus.spawn_game_menu.emit(game_menu)
	game_menu.setup(title, options, small_mode)
	return game_menu
