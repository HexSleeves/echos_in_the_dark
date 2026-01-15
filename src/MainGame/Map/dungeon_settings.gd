class_name DungeonSettings
extends Resource

@export_category("Map Dimensions")
@export var map_width: int = 80
@export var map_height: int = 45

@export_category("Rooms RNG")
@export var max_rooms: int = 30
@export var room_min_size: int = 6
@export var room_max_size: int = 10

@export_category("Monsters RNG")
@export var max_monsters_per_room: Dictionary[int, int] = {
	1: 2,
	4: 3,
	6: 5,
}
@export var monster_chances: Dictionary[String, Dictionary] = {
	"orc": {1: 80},
	"troll": {
		3: 15,
		5: 30,
		7: 60,
	}
}

@export_category("Items RNG")
@export var max_items_per_room: Dictionary[int, int] = {
	1: 1,
	4: 2,
}

@export var item_chances: Dictionary[String, Dictionary] = {
	"healing_potion": {1: 35},
	"lightning_scroll": {4: 25},
	"fireball_scroll": {6: 25},
	"confusion_scroll": {2: 10},
	"sword": {4: 5},
	"chain_mail": {6: 15},
	"torch": {1: 40},
	"lantern": {3: 15, 5: 25},
}

func get_floor_value(config_dict: Dictionary, current_floor: int) -> int:
	var sorted_keys = config_dict.keys()
	sorted_keys.sort()
	var current_value: int = 0
	for key: int in sorted_keys:
		if key > current_floor:
			break
		current_value = config_dict[key]
	return current_value
