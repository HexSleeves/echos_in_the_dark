@abstract
class_name StatusEffect
extends Resource

signal effect_ended
signal effect_changed


func merge(_new_effect: StatusEffect) -> void:
	pass


func process_message_precalculate(_entity: Entity, _message: Message) -> void:
	pass


func process_message_execute(_entity: Entity, _message: Message)-> void:
	pass


func start(_entity: Entity) -> void:
	pass


func end(_entity: Entity) -> void:
	pass


@abstract func get_type() -> String
