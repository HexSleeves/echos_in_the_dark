class_name MineAction
extends ActionWithDirection


func perform() -> bool:
	var destination := get_destination()
	var entities_at_dest := _performing_entity.map_data.get_entities_at_position(destination)
	
	# Find a mineable entity at the destination
	var mineable_entity: Entity = null
	for entity: Entity in entities_at_dest:
		if entity.has_component(Component.Type.Mineable):
			mineable_entity = entity
			break
	
	if not mineable_entity:
		Log.send_log("Nothing to mine there.", Log.COLOR_IMPOSSIBLE)
		return false
	
	var mineable: MineableComponent = mineable_entity.get_component(Component.Type.Mineable)
	if mineable.depleted:
		Log.send_log("This deposit is already depleted.", Log.COLOR_IMPOSSIBLE)
		return false
	
	# Perform mining
	var mine_message := Message.new("mine").with_data({"miner": _performing_entity})
	mineable_entity.process_message(mine_message)
	
	return mine_message.flags.get("did_mine", false)
