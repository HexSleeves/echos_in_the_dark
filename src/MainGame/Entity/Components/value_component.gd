class_name ValueComponent
extends Component

## The gold value of this item when sold
@export var sell_value: int = 0


func get_component_type() -> Type:
	return Type.Value
