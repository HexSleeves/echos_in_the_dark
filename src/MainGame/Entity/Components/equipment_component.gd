class_name EquipmentComponent
extends Component

enum Slot {
	Head,
	Body,
	Neck,
	Feet,
	Cloak,
	MainHand,
	OffHand,
	LightSource,
}

@export var starting_equipment: Array[Entity]
@export_storage var equipped: Dictionary[Slot, Entity]


func _enter_entity() -> void:
	for equipment_template: Entity in starting_equipment:
		var equipment := equipment_template.reify()
		equip(equipment, false)
		_parent_entity.process_message(Message.new("obtain_item").with_data({"item": equipment}))


func process_message_precalculate(message: Message) -> void:
	for equippable_component: EquippableComponent in equipped.values().map(
		func(e: Entity) -> EquippableComponent: return e.get_component(Component.Type.Equippable)
	):
		equippable_component.apply_effect_precalculate(message)


func process_message_execute(message: Message) -> void:
	for equippable_component: EquippableComponent in equipped.values().map(
		func(e: Entity) -> EquippableComponent: return e.get_component(Component.Type.Equippable)
	):
		equippable_component.apply_effect_execute(message)
	match message.type:
		"equip_item":
			var item: Entity = message.data.get("item")
			if item:
				message.flags["did_equip"] = toggle_equip(item, true)
		"dropped":
			var item: Entity = message.data.get("item")
			if is_equipped(item):
				unequip(item, false)


func is_equipped(item: Entity) -> bool:
	return item in equipped.values()


func toggle_equip(item: Entity, with_message: bool) -> bool:
	if is_equipped(item):
		return unequip(item, with_message)
	else:
		return equip(item, with_message)


func equip(item: Entity, with_message: bool) -> bool:
	var equippable: EquippableComponent = item.get_component(Component.Type.Equippable)
	assert(equippable != null)
	var slot: Slot = equippable.slot
	if equipped.has(slot):
		unequip(equipped[slot], with_message)
	equipped[slot] = item
	if with_message:
		Log.send_log("You equip %s." % item.get_entity_name())
	return true


func unequip(item: Entity, with_message: bool) -> bool:
	var equippable: EquippableComponent = item.get_component(Component.Type.Equippable)
	assert(equippable != null)
	var slot: Slot = equippable.slot
	if equipped.get(slot, null) == item:
		equipped.erase(slot)
		if with_message:
			Log.send_log("You unequip %s." % item.get_entity_name())
		return true
	return false


func get_component_type() -> Type:
	return Type.Equipment
