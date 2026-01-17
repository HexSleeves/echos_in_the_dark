class_name MineableComponent
extends Component

## The entity key to spawn when mined (from ResourceCollection)
@export var ore_type: String = "copper_ore"

## How many turns it takes to mine this deposit
@export var mining_time: int = 1

## Min/max ore yield when mined
@export var min_yield: int = 1
@export var max_yield: int = 3

## Whether this deposit has been depleted
@export_storage var depleted: bool = false


func process_message_execute(message: Message) -> void:
	match message.type:
		"mine":
			if depleted:
				Log.send_log("This deposit is depleted.", Log.COLOR_IMPOSSIBLE)
				return
			
			var miner: Entity = message.data.get("miner")
			if not miner:
				return
			
			# Calculate yield
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var yield_amount: int = rng.randi_range(min_yield, max_yield)
			
			# Spawn ore items at the deposit location
			var position: Vector2i = PositionComponent.get_entity_position(_parent_entity)
			var resource_collection = preload("res://resources/ResourceCollection.tres")
			
			for i in yield_amount:
				var ore: Entity = resource_collection.entities[ore_type].reify()
				_parent_entity.map_data.spawn_entity_at(ore, position)
			
			Log.send_log(
				"%s mined %d %s!" % [
					miner.get_entity_name().capitalize(),
					yield_amount,
					ore_type.replace("_", " ")
				],
				Log.COLOR_POSITIVE
			)
			
			# Mark as depleted and update visual
			depleted = true
			_parent_entity.process_message(Message.new("visual_update").with_data({
				"color": Color(0.3, 0.3, 0.3, 1)
			}))
			message.flags["did_mine"] = true


func get_component_type() -> Type:
	return Type.Mineable
