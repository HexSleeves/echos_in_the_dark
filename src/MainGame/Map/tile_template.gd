class_name TileTemplate
extends Resource

@export var name: String
@export var texture: AtlasTexture
@export var blocks_movement: bool = true
@export var blocks_sight: bool = true
@export var light_color: Color = Color.WHITE
@export var dark_color: Color = Color.DIM_GRAY

@export_category("Mining")
@export var mineable: bool = false
@export var ore_type: String = ""  # Key in ResourceCollection.entities
@export var min_yield: int = 1
@export var max_yield: int = 3
