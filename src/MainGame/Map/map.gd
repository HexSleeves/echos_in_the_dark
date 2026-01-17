class_name Map
extends Node2D

signal map_data_set(map_data)

@onready var tiles: Node2D = $Tiles
@onready var entities: Node2D = $Entities

const PLAYER = preload("res://resources/entities/player.tres")

var _map_data: MapData:
	set = set_map_data


func generate_new_dungeon(target_floor: int = 1) -> void:
	await get_tree().process_frame
	var player: Entity = null
	if _map_data:
		player = _map_data.player_entity
		_map_data.remove_entity(player)
	else:
		player = PLAYER.reify()
		
	var dungeon_generator := DungeonGenerator.new()
	_map_data = dungeon_generator.generate_dungeon(player, target_floor)


func set_map_data(new_map_data: MapData) -> void:
	for tile_node: Node in tiles.get_children():
		tile_node.queue_free()
	for entity_node: Node in entities.get_children():
		entity_node.queue_free()
	_map_data = new_map_data
	_map_data.entity_sprite_spawned.connect(entities.add_child)
	_map_data.tile_sprite_added.connect(tiles.add_child)
	_map_data.new_map_requested.connect(generate_new_dungeon)
	#_map_data.draw_entities()
	_map_data.call_deferred("draw_entities")
	for tile_sprite: Node in _map_data.get_tile_sprites():
		tiles.add_child(tile_sprite)
	map_data_set.emit(new_map_data)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _map_data.player_entity.has_component(Component.Type.Durability):
			SignalBus.save.emit(_map_data, true)
		else:
			SignalBus.delete_save.emit(true)
