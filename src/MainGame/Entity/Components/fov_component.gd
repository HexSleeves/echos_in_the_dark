class_name FovComponent
extends Component

const multipliers = [
	[1, 0, 0, -1, -1, 0, 0, 1],
	[0, 1, -1, 0, 0, -1, 1, 0],
	[0, 1, 1, 0, 0, -1, -1, 0],
	[1, 0, 0, 1, -1, 0, 0, -1]
]

## Base vision radius without any light source (near-blind in darkness)
@export var radius: int = 2

var _fov: Dictionary[Vector2i, bool] = {}


func process_message_precalculate(message: Message) -> void:
	match message.type:
		"recalculate_fov":
			var radius_calculation: MessageCalculation = message.get_calculation("radius")
			radius_calculation.base_value = radius


func process_message_execute(message: Message) -> void:
	match message.type:
		"recalculate_fov":
			var effective_radius: int = message.get_calculation("radius").get_result()
			if not message.data.has("position"):
				return
			var position: Vector2i = message.data["position"]
			_update_fov(_parent_entity.map_data, position, effective_radius)
			_parent_entity.map_data.set_fov(_fov)
		"position_update", "map_entered":
			_parent_entity.process_message(Message.new("recalculate_fov"))


func _update_fov(map_data: MapData, origin: Vector2i, radius: int) -> void:
	_fov = {origin: true}
	for i in 8:
		_cast_light(map_data, origin.x, origin.y, radius, 1, 1.0, 0.0, multipliers[0][i], multipliers[1][i], multipliers[2][i], multipliers[3][i])


func _cast_light(
	map_data: MapData,
	x: int,
	y: int,
	radius: int,
	row: int,
	start_slope: float,
	end_slope: float,
	xx: int,
	xy: int,
	yx: int,
	yy: int,
):
	if start_slope < end_slope:
		return
	var next_start_slope: float = start_slope
	var radius2: int = radius * radius
	for i in range(row, radius + 1):
		var blocked: bool = false
		var dy: int = -i
		for dx in range(-i, 1):
			var l_slope: float = (dx - 0.5) / (dy + 0.5)
			var r_slope: float = (dx + 0.5) / (dy - 0.5)
			if start_slope < r_slope:
				continue
			elif end_slope > l_slope:
				break
			var sax: int = dx * xx + dy * xy
			var say: int = dx * yx + dy * yy
			if ((sax < 0 and absi(sax) > x) or (say < 0 and absi(say) > y)):
				continue
			var ax: int = x + sax
			var ay: int = y + say
			var current_grid_position := Vector2i(ax, ay)
			var current_tile: Tile = map_data.tiles.get(current_grid_position)
			var sight_blocked: bool = current_tile.blocks_sight
			if not current_tile:
				continue
			if (dx * dx + dy * dy) < radius2:
				_fov[current_grid_position] = true
			if blocked:
				if sight_blocked:
					next_start_slope = r_slope
					continue
				else:
					blocked = false
					start_slope = next_start_slope
			elif sight_blocked:
				blocked = true
				next_start_slope = r_slope
				_cast_light(map_data, x, y, radius, i + 1, start_slope, l_slope, xx, xy, yx, yy)
		if blocked:
			break


func get_component_type() -> Type:
	return Type.FOV
