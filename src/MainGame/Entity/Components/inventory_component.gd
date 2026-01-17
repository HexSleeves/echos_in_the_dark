class_name InventoryComponent
extends Component

@export var capacity: int = 24
@export_storage var items: Array[Entity]


func process_message_execute(message: Message) -> void:
	match message.type:
		"obtain_item":
			var item: Entity = message.data.get("item")
			if item and items.size() < capacity:
				items.append(item)
		"take_item":
			var item: Entity = message.data.get("item")
			var verb: String = message.data.get("verb", "take")
			var verb_past_tense: String = message.data.get("verb_past_tense", "took")
			assert(item != null)
			
			# Check if item has a sell value (like ore) - auto-sell it
			var value_component: ValueComponent = item.get_component(Component.Type.Value)
			if value_component and value_component.sell_value > 0:
				_parent_entity.map_data.remove_entity(item)
				var gold_message := Message.new("gain_gold")
				gold_message.get_calculation("amount").base_value = value_component.sell_value
				_parent_entity.process_message(gold_message)
				Log.send_log(
					"%s collected %s (worth %d gold)" % [
						_parent_entity.get_entity_name().capitalize(),
						item.get_entity_name(),
						value_component.sell_value
					]
				)
				message.flags["did_take_item"] = true
				return
			
			if items.size() >= capacity:
				Log.send_log(
					"%s cannot %s %s (inventory is full)" % [
						_parent_entity.get_entity_name(),
						verb,
						item.get_entity_name()
					],
					Log.COLOR_IMPOSSIBLE
				)
				return
			_parent_entity.map_data.remove_entity(item)
			items.append(item)
			Log.send_log(
				"%s %s %s" % [
					_parent_entity.get_entity_name().capitalize(),
					verb_past_tense,
					item.get_entity_name()
				]
			)
			message.flags["did_take_item"] = true
		"drop_item":
			var can_drop: bool = message.flags.get("can_drop", true)
			if not can_drop:
				return
			var item: Entity = message.data.get("item")
			assert(item != null and item in items)
			items.erase(item)
			var parent_position := PositionComponent.get_entity_position(_parent_entity)
			_parent_entity.map_data.spawn_entity_at(item, parent_position)
			_parent_entity.process_message(Message.new("dropped_item").with_data({"item": item}))
			Log.send_log("%s dropped %s" % [_parent_entity.get_entity_name().capitalize(), item.get_entity_name()])
			message.flags["did_drop_item"] = true
		"reactivate":
			for item: Entity in items:
				item.reactivate(null)


func get_component_type() -> Type:
	return Type.Inventory
