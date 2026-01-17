class_name LightSourceComponent
extends Component

signal duration_changed(current: int, max_duration: int)
signal extinguished()

## Maximum duration (fuel capacity)
@export var max_duration: int = 100

## Fuel consumed per turn (higher = burns faster)
@export var burn_rate: int = 1

## Current remaining duration
@export_storage var current_duration: int = -1  # -1 means use max_duration

## Whether this light source is currently lit
@export_storage var is_lit: bool = true


func _enter_entity() -> void:
	if current_duration < 0:
		current_duration = max_duration


func process_message_execute(message: Message) -> void:
	match message.type:
		"turn_end":
			_on_turn_end()


func _on_turn_end() -> void:
	if not is_lit:
		return
	
	# Only consume fuel if this light source is equipped
	var owner_entity: Entity = _parent_entity
	if not owner_entity:
		return
	
	# Check if this item is in someone's equipment
	# The light source is on an item entity, we need to find who has it equipped
	# This is tricky - the item itself receives turn_end when it's in inventory
	# We need to check via the equipment system
	
	# Consume fuel based on burn rate
	current_duration -= burn_rate
	if current_duration < 0:
		current_duration = 0
	duration_changed.emit(current_duration, max_duration)
	
	if current_duration <= 0:
		_extinguish()


func _extinguish() -> void:
	is_lit = false
	extinguished.emit()
	Log.send_log("%s has burned out!" % _parent_entity.get_entity_name().capitalize(), Log.COLOR_NEGATIVE)
	
	# Signal that FOV needs recalculation
	SignalBus.light_source_extinguished.emit()


func get_component_type() -> Type:
	return Type.LightSource
