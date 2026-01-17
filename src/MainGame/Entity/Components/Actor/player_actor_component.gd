class_name PlayerActorComponent
extends ActorComponent

enum PauseOptions {
	Continue,
	SaveAndReturn,
	SaveAndQuit,
	NUM_PAUSE_OPTIONS
}

const PauseOptionStrings = {
	PauseOptions.Continue: "Continue",
	PauseOptions.SaveAndReturn: "Save and return to Main Menu",
	PauseOptions.SaveAndQuit: "Save and Quit",
}

const CHARACTER_INFO_CONTAINER = preload("res://src/MainGame/GUI/InfoContainers/character_info_container.tscn")

func _enter_entity() -> void:
	_register_input()


func _register_input() -> void:
	InputStack.register_input_callback(_on_event)


func before_exit() -> void:
	InputStack.pop_stack()


func process_message_execute(message: Message) -> void:
	super.process_message_execute(message)
	match message.type:
		"reactivate":
			_register_input()


func _on_event(event: InputEvent) -> void:
	if event.is_released():
		return
	
	if event.is_action_pressed("zoom_in"):
		_parent_entity.process_message(Message.new("zoom_in"))
	if event.is_action_pressed("zoom_out"):
		_parent_entity.process_message(Message.new("zoom_out"))
		
	if event.is_action_pressed("look"):
		var position := PositionComponent.get_entity_position(_parent_entity)
		var reticle_config := ReticleConfig.new(_parent_entity.map_data, position).with_info(ReticleConfig.Info.Look)
		SignalBus.reticle_requested.emit(reticle_config)
	
	var move_offset := Vector2i.ZERO
	
	if event.is_action("move_left"):
		move_offset += Vector2i.LEFT
	elif event.is_action("move_right"):
		move_offset += Vector2i.RIGHT
	elif event.is_action("move_up"):
		move_offset += Vector2i.UP
	elif event.is_action("move_down"):
		move_offset += Vector2i.DOWN
	elif event.is_action("move_up_left"):
		move_offset += Vector2i.UP + Vector2i.LEFT
	elif event.is_action("move_up_right"):
		move_offset += Vector2i.UP + Vector2i.RIGHT
	elif event.is_action("move_down_left"):
		move_offset += Vector2i.DOWN + Vector2i.LEFT
	elif event.is_action("move_down_right"):
		move_offset += Vector2i.DOWN + Vector2i.RIGHT
	
	if move_offset != Vector2i.ZERO:
		_queued_action = BumpAction.new(_parent_entity, move_offset)
	
	if event.is_action("wait"):
		_queued_action = WaitAction.new(_parent_entity)
	
	if event.is_action("pickup"):
		_queued_action = PickupAction.new(_parent_entity)
	
	if event.is_action("mine"):
		_handle_mine()
	
	if event.is_action("drop"):
		var item: Entity = await _get_item("select an item to drop")
		if item:
			_queued_action = DropAction.new(_parent_entity, item)
	
	if event.is_action("inventory"):
		_handle_inventory()
	
	if event.is_action("descend"):
		_queued_action = TakeStairsAction.new(_parent_entity)
	
	if event.is_action("ui_cancel"):
		_handle_pause_menu()
		
	if event.is_action("character_info"):
		var character_info_container: CharacterInfoContainer = CHARACTER_INFO_CONTAINER.instantiate()
		SignalBus.spawn_info_container.emit(character_info_container)
		character_info_container.setup(_parent_entity)


func _handle_inventory() -> void:
	var item: Entity = await _get_item("select item to use")
	if not item:
		return
	if item.has_component(Component.Type.Use):
		_handle_use_item(item)
	if item.has_component(Component.Type.Equippable):
		_queued_action = ToggleEquipmentAction.new(_parent_entity, item)


func _handle_use_item(item) -> void:
	var use_target := UsableComponent.get_use_target(item)
	if not use_target:
		return
	var targets: Array[Entity] = await use_target.get_targets(_parent_entity)
	if targets.is_empty():
		return
	_queued_action = UseAction.new(_parent_entity, item, targets)


func _get_item(prompt: String = "") -> Entity:
	var inventory: InventoryComponent = _parent_entity.get_component(Component.Type.Inventory)
	var equipment: EquipmentComponent = _parent_entity.get_component(Component.Type.Equipment)
	var item_names: Array = inventory.items.map(
		func(e: Entity) -> String: return e.name + " (equipped)" if equipment.is_equipped(e) else e.name
	)
	var game_menu: GameMenu = MainGame.spawn_game_menu("Inventory", item_names)
	if not prompt.is_empty():
		game_menu.with_prompt(prompt)
	var item_index: int = await game_menu.option_selected
	if item_index < 0 or item_index >= inventory.items.size():
		return null
	return inventory.items[item_index]


func _handle_pause_menu() -> void:
	var pause_options := []
	for i: int in PauseOptions.NUM_PAUSE_OPTIONS:
		pause_options.append(PauseOptionStrings[i])
	var pause_menu: GameMenu = MainGame.spawn_game_menu("Pause", pause_options, true)
	var pause_index: int = await pause_menu.option_selected
	match pause_index:
		PauseOptions.SaveAndReturn:
			SignalBus.save.emit(_parent_entity.map_data, false)
		PauseOptions.SaveAndQuit:
			SignalBus.save.emit(_parent_entity.map_data, true)


func _handle_mine() -> void:
	# Let player choose a direction to mine
	var position := PositionComponent.get_entity_position(_parent_entity)
	var reticle_config := ReticleConfig.new(_parent_entity.map_data, position)
	reticle_config.max_range = 1
	reticle_config.on_select = func(target_pos: Vector2i) -> void:
		var offset := target_pos - position
		if offset != Vector2i.ZERO:
			_queued_action = MineAction.new(_parent_entity, offset)
	SignalBus.reticle_requested.emit(reticle_config)
