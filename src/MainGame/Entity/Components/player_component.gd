class_name PlayerComponent
extends Component


func process_message_execute(message: Message) -> void:
	match message.type:
		"died":
			var menu: GameMenu = MainGame.spawn_game_menu("You Died", ["To Main Menu", "Quit"], true)
			var index: int = await menu.option_selected
			var quit := true
			if index == 0:
				quit = false
			SignalBus.delete_save.emit(quit)


func get_component_type() -> Type:
	return Type.Player
