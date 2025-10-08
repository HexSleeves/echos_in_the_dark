class_name Entity
extends Resource

@export var name: String
@export var is_proper_name: bool = false
@export var initial_components: Array[Component]
@export var base_entity: Entity

@export_storage var _components: Dictionary[Component.Type, Component]

var map_data: MapData:
	set(value):
		_map_data_ref = weakref(value)
	get:
		return _map_data_ref.get_ref() as MapData
var _map_data_ref: WeakRef = weakref(null)

var _message_queue: Array[Message]


func _get_initial_components() -> Array[Component]:
	var empty_array: Array[Component] = []
	var components: Array[Component] = base_entity._get_initial_components() if base_entity else empty_array
	components.append_array(initial_components)
	return components


func reify() -> Entity:
	var reified_entity: Entity = self.duplicate(true)
	reified_entity.initial_components = []
	reified_entity.base_entity = null
	
	var component_list := _get_initial_components()
	for component: Component in component_list:
		reified_entity.enter_component(component.duplicate(true))
	
	return reified_entity


func enter_component(component: Component) -> void:
	_components[component.type] = component
	component.enter_entity(self)


func has_component(component_type: Component.Type) -> bool:
	return _components.has(component_type)


func get_component(component_type: Component.Type) -> Component:
	return _components.get(component_type, null)


func remove_component(component_type: Component.Type) -> Component:
	var component := get_component(component_type)
	if component:
		component.before_exit()
		_components.erase(component_type)
	return component


func place_at(position: Vector2i, map_data: MapData) -> Entity:
	self.map_data = map_data
	var position_component := PositionComponent.new()
	enter_component(position_component)
	position_component.position = position
	return self


func process_message(message: Message) -> void:
	_message_queue.append(message)
	if _message_queue.size() > 1:
		return
	while not _message_queue.is_empty():
		for component: Component in _components.values():
			component.process_message_precalculate(_message_queue.front())
		for component: Component in _components.values():
			component.process_message_execute(_message_queue.front())
		_message_queue.pop_front()


func add_status_effect(effect: StatusEffect) -> void:
	if not has_component(Component.Type.StatusEffects):
		enter_component(StatusEffectsComponent.new())
	process_message(Message.new("add_status_effect").with_data({"effect": effect}))


func get_entity_name(indefinite: bool = false) -> String:
	if is_proper_name:
		return name
	elif indefinite:
		if name.substr(0, 1).to_lower() in ["a", "e", "i", "o"]:
			return "an " + name
		else:
			return "a " + name
	else:
		return "the " + name


func reactivate(map_data: MapData) -> void:
	self.map_data = map_data
	for component: Component in _components.values():
		component._parent_entity = self
	process_message(Message.new("reactivate"))
