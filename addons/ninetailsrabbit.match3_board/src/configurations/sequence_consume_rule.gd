class_name SequenceConsumeRule extends Resource

@export var id: StringName
## The rules are ordered by priority, rules with higher priority values are checked first
@export var priority: int = 0:
	set(value):
		priority = maxi(0, value)
## When this property is enabled, the sequence and the target pieces needs to have the same size
@export var strict_size_comparison: bool = false
@export var shapes: Array[Match3Sequence.Shapes] = []
@export var piece_to_spawn: Match3PieceConfiguration
## Piece IDs order are readed from left to right for horizontal shapes
## and vertical shapes top to bottom (where left is top)
@export var target_pieces: Array[Match3PieceConfiguration] = []


func meet_conditions(sequence: Match3Sequence) -> bool:
	if not shapes.has(sequence.shape):
		return false
	
	var sequence_pieces: Array[Match3Piece] = sequence.normal_pieces()
	var pieces_configuration: Array[Match3PieceConfiguration] = target_pieces.duplicate()
	
	if strict_size_comparison and sequence_pieces.size() != target_pieces.size():
		return false
	
	var contain_all_pieces: bool = true
	var valid_pieces: Array[bool] = []
	
	for piece: Match3Piece in sequence_pieces:
		if pieces_configuration.is_empty():
			break
			
		var found_pieces = pieces_configuration.filter(
			func(conf: Match3PieceConfiguration): return piece.id == conf.id)
		
		if found_pieces.size() > 0:
			pieces_configuration.erase(found_pieces.front())
			valid_pieces.append(true)
	
	if strict_size_comparison:
		contain_all_pieces = valid_pieces.size() == target_pieces.size()
	else:
		contain_all_pieces = valid_pieces.size() >= target_pieces.size()
		
	return contain_all_pieces
