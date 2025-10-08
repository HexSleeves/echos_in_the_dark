class_name MovementBlockerComponent
extends Component


func _enter_entity() -> void:
	_parent_entity.process_message(Message.new("pathfinder_update"))


func before_exit() -> void:
	_parent_entity.process_message(Message.new("pathfinder_update").with_flags({"solid": false}))


func process_message_execute(message: Message) -> void:
	match message.type:
		"map_entered":
			_parent_entity.process_message(Message.new("pathfinder_update"))
		"pathfinder_update":
			if not message.data.has("position"):
				return
			var solid: bool = message.flags.get("solid", true)
			if _parent_entity.map_data:
				_parent_entity.map_data.pathfinder_set_point(message.data.get("position"), solid)
		"position_update":
			_parent_entity.map_data.pathfinder_set_point(message.data.get("position"), true)
			_parent_entity.map_data.pathfinder_set_point(message.data.get("old_position"), false)


func get_component_type() -> Type:
	return Type.MovementBlocker
