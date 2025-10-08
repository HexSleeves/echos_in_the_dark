@abstract
class_name Action
extends RefCounted


var _performing_entity: Entity


func _init(performing_entity: Entity) -> void:
	_performing_entity = performing_entity


func perform() -> bool:
	return false


func _check_message_flag(message: Message, flag_key: String) -> bool:
	return message.flags.get(flag_key, false)
