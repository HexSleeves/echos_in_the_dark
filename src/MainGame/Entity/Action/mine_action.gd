class_name MineAction
extends ActionWithDirection

const RESOURCE_COLLECTION = preload("res://resources/ResourceCollection.tres")


func perform() -> bool:
	var destination := get_destination()
	var map_data: MapData = _performing_entity.map_data
	
	# Check if there's a mineable tile at destination
	var tile: Tile = map_data.tiles.get(destination)
	if not tile:
		Log.send_log("Nothing to mine there.", Log.COLOR_IMPOSSIBLE)
		return false
	
	var template: TileTemplate = tile.template
	if not template.mineable:
		Log.send_log("Nothing to mine there.", Log.COLOR_IMPOSSIBLE)
		return false
	
	# Calculate yield
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var yield_amount: int = rng.randi_range(template.min_yield, template.max_yield)
	
	# Spawn ore items at the miner's position
	var miner_pos: Vector2i = PositionComponent.get_entity_position(_performing_entity)
	for i in yield_amount:
		var ore: Entity = RESOURCE_COLLECTION.entities[template.ore_type].reify()
		map_data.spawn_entity_at(ore, miner_pos)
	
	Log.send_log(
		"%s mined %d %s!" % [
			_performing_entity.get_entity_name().capitalize(),
			yield_amount,
			template.ore_type.replace("_", " ")
		],
		Log.COLOR_POSITIVE
	)
	
	# Replace the ore wall with regular floor
	map_data.replace_tile(destination, RESOURCE_COLLECTION.tiles["floor"])
	
	# Update pathfinder since we created a new walkable tile
	map_data.pathfinder.set_point_solid(destination, false)
	
	# Recalculate FOV since we may have opened up visibility
	_performing_entity.process_message(Message.new("recalculate_fov"))
	
	return true
