class_name LightRadiusEquippableEffect
extends EquippableEffect

@export var radius_bonus: int = 0


func process_message_precalculate(message: Message) -> void:
	match message.type:
		"recalculate_fov":
			message.get_calculation("radius").terms.append(radius_bonus)
