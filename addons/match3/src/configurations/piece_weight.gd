class_name Match3PieceWeight extends Resource

@export var value: float = 1.0:
	set(value):
		value = maxf(0.0, value)
		
var current_weight: float = value
var total_accum_weight: float = 0.0

	
func reset_accum_weight() -> void:
	total_accum_weight = 0.0


func change_weight(new_value: float) -> void:
	current_weight = new_value


func change_to_original_weight() -> void:
	current_weight = value
