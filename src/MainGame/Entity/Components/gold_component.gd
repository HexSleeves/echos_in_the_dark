class_name GoldComponent
extends Component

signal gold_changed(current_gold: int)

@export_storage var gold: int = 0:
	set = set_gold


func set_gold(value: int) -> void:
	gold = maxi(0, value)
	gold_changed.emit(gold)


func process_message_execute(message: Message) -> void:
	match message.type:
		"gain_gold":
			var amount: int = message.get_calculation("amount").get_result()
			if amount > 0:
				gold += amount
				Log.send_log("You gained %d gold." % amount, Log.COLOR_POSITIVE)
		"spend_gold":
			var amount: int = message.get_calculation("amount").get_result()
			if amount > gold:
				message.flags["insufficient_gold"] = true
				Log.send_log("Not enough gold!", Log.COLOR_IMPOSSIBLE)
			else:
				gold -= amount
				message.flags["gold_spent"] = true


func get_component_type() -> Type:
	return Type.Gold
