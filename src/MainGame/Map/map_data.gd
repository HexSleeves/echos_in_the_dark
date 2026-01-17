class_name MapData
extends Resource

signal entity_sprite_spawned(entity_sprite)
signal new_map_requested(new_map_floor)
signal tile_sprite_added(tile_sprite)

const BLOCKING_ENTITY_PATHFIND_WEIGHT = 5
var _TILE_SIZE: Vector2 = ProjectSettings.get_setting("global/tile_size")

@export_storage var entities: Array[Entity]
@export_storage var entities_by_position: Dictionary[Vector2i, Array]
@export_storage var tiles: Dictionary[Vector2i, Tile]
@export_storage var size: Vector2i
@export_storage var player_entity: Entity
@export_storage var fov: Dictionary[Vector2i, bool] = {}
@export_storage var current_floor: int = 1

var pathfinder: AStarGrid2D

func spawn_entity_at(entity: Entity, position: Vector2i) -> void:
	entity.place_at(position, self)
	entities.append(entity)
	draw_entity(entity)
	entity.process_message(Message.new("map_entered"))


func remove_entity(entity: Entity) -> void:
	entities.erase(entity)
	var position_component: PositionComponent = entity.get_component(Component.Type.Position)
	if position_component:
		entities_by_position[position_component.position].erase(entity)
	entity.map_data = null
	entity.process_message(Message.new("exit_map"))


func draw_entities() -> void:
	for entity: Entity in entities:
		draw_entity(entity)


func reactivate() -> void:
	for entity: Entity in entities:
		entity.reactivate(self)
	setup_pathfinder()
	


func get_tile_sprites() -> Array:
	return tiles.values().map(func(t: Tile) -> Sprite2D: return t.get_sprite())


func draw_entity(entity: Entity) -> void:
	var drawable_component: DrawableComponent = entity.get_component(Component.Type.Drawable) as DrawableComponent
	if drawable_component:
		entity_sprite_spawned.emit(drawable_component.get_sprite())
	else:
		push_warning("Tried drawing non-drawable entity '%s'" % entity.name)


func get_entities_with_components(component_types: Array[Component.Type]) -> Array[Entity]:
	return entities.filter(
		func(e: Entity) -> bool:
			return component_types.all(
				func(t: Component.Type) -> bool:
					return e.has_component(t)
			)
	)


func get_entities_at_position(position: Vector2i) -> Array[Entity]:
	return Array(entities_by_position.get(position, []), TYPE_OBJECT, "Resource", Entity)


func get_blocking_entity_at_position(position: Vector2i) -> Entity:
	var blocking_entities := get_entities_at_position(position).filter(
		func(e: Entity) -> bool:
			return e.has_component(Component.Type.MovementBlocker)
	)
	return null if blocking_entities.is_empty() else blocking_entities.front()


func set_tile(tile_position: Vector2i, tile_template: TileTemplate) -> Tile:
	if not Rect2i(Vector2i.ZERO, size).has_point(tile_position):
		return null
	var tile := Tile.new()
	tile.setup(tile_template, tile_position)
	tiles[tile_position] = tile
	return tile


func replace_tile(tile_position: Vector2i, tile_template: TileTemplate) -> Tile:
	"""Replace an existing tile at runtime, updating the visual."""
	if not Rect2i(Vector2i.ZERO, size).has_point(tile_position):
		return null
	
	# Remove old tile sprite
	var old_tile: Tile = tiles.get(tile_position)
	if old_tile:
		var old_sprite = old_tile.get_sprite()
		if old_sprite:
			old_sprite.queue_free()
	
	# Create new tile
	var tile := Tile.new()
	tile.setup(tile_template, tile_position)
	tile.is_explored = true  # Keep it explored since we're replacing
	tile.is_in_view = fov.get(tile_position, false)
	tiles[tile_position] = tile
	
	# Emit signal to add new sprite
	tile_sprite_added.emit(tile.get_sprite())
	
	return tile


func set_fov(new_fov: Dictionary[Vector2i, bool]) -> void:
	for position: Vector2i in fov:
		tiles.get(position).is_in_view = false
	fov = new_fov
	for position: Vector2i in fov:
		tiles.get(position).is_in_view = true
	for entity: Entity in entities:
		entity.process_message(Message.new("fov_update").with_data({"fov": fov}))


func is_in_fov(position: Vector2i) -> bool:
	return fov.get(position, false)


func setup_pathfinder() -> void:
	pathfinder = AStarGrid2D.new()
	pathfinder.region = Rect2i(Vector2i.ZERO, size)
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	pathfinder.default_compute_heuristic = AStarGrid2D.HEURISTIC_CHEBYSHEV
	pathfinder.default_estimate_heuristic = AStarGrid2D.HEURISTIC_CHEBYSHEV
	pathfinder.update()
	for tile_position: Vector2i in tiles:
		var tile: Tile = tiles[tile_position]
		pathfinder.set_point_solid(tile_position, tile.blocks_movement)
	for entity: Entity in get_entities_with_components([Component.Type.Position, Component.Type.MovementBlocker]):
		var entity_position: Vector2i = (entity.get_component(Component.Type.Position) as PositionComponent).position
		pathfinder.set_point_weight_scale(entity_position, BLOCKING_ENTITY_PATHFIND_WEIGHT)


func pathfinder_set_point(point: Vector2i, blocked: bool) -> void:
	if not pathfinder:
		return
	var weight := BLOCKING_ENTITY_PATHFIND_WEIGHT if blocked else 1
	pathfinder.set_point_weight_scale(point, weight)


func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(world_position / _TILE_SIZE)


func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * _TILE_SIZE
