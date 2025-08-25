class_name StatusEffectsComponent
extends Component

signal effects_changed

@export_storage var effects: Dictionary[String, StatusEffect]


func add_effect(effect: StatusEffect) -> void:
	var effect_type := effect.get_type()
	if effects.has(effect_type):
		var existing_effect: StatusEffect = effects.get(type)
		existing_effect.merge(effect)
	else:
		effects[effect_type] = effect
		effect.effect_ended.connect(_on_effect_ended.bind(type))
		effect.effect_changed.connect(_on_effect_changed)
		effect.start(_parent_entity)
	effects_changed.emit()


func _on_effect_ended(effect_type: String) -> void:
	end_effect(effect_type)


func _on_effect_changed() -> void:
	effects_changed.emit()


func end_effect(effect_type: String) -> void:
	var effect: StatusEffect = effects.get(effect_type)
	if effect:
		effect.end(_parent_entity)
		effects.erase(effect_type)
		effects_changed.emit()


func process_message_precalculate(message: Message) -> void:
	for effect: StatusEffect in effects.values():
		effect.process_message_precalculate(_parent_entity, message)
	match message.type:
		"add_status_effect":
			var effect: StatusEffect = message.data.get("effect")
			if effect:
				add_effect(effect)
		"remove_status_effect":
			var effect_type: String = message.data.get("effect_type", "")
			end_effect(effect_type)


func process_message_execute(message: Message) -> void:
	for effect: StatusEffect in effects.values():
		effect.process_message_execute(_parent_entity, message)


func get_component_type() -> Type:
	return Type.StatusEffects
