class_name Match3PieceGenerator extends RefCounted


var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## It's preferred to have his own available pieces array to not depend on the board one so we can
## decide what pieces are generated or not
var available_pieces: Array[Match3PieceConfiguration] = []


func _init() -> void:
	rng.randomize()


func add_pieces(pieces: Array[Match3PieceConfiguration]) -> void:
	for piece: Match3PieceConfiguration in pieces:
		add_piece(piece)


func add_piece(piece: Match3PieceConfiguration) -> void:
	if available_pieces.has(piece):
		return
		
	available_pieces.append(piece)


func roll(except: Array[Match3PieceConfiguration] = []) -> Match3PieceConfiguration:
	var available_pieces_to_roll = available_pieces.filter(
		func(piece: Match3PieceConfiguration): return not except.has(piece))
		
	var selected_piece: Match3PieceConfiguration
	
	assert(available_pieces_to_roll.size() > 0, "Match3PieceGenerator: No pieces available to roll")
	
	available_pieces_to_roll.shuffle()
	selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	while selected_piece == null:
		selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	return selected_piece
	

func _prepare_weight(pieces: Array[Match3PieceConfiguration]) -> float:
	var total_weight: float = 0.0
	
	for piece: Match3PieceConfiguration in pieces:
		piece.weight.reset_accum_weight()
		
		total_weight += piece.weight.current_weight
		piece.weight.total_accum_weight = total_weight
	
	return total_weight


func _roll_piece(pieces: Array[Match3PieceConfiguration], total_weight: float) -> Match3PieceConfiguration:
	var threshold: float = rng.randf_range(0.0, total_weight)
	var selected_piece: Match3PieceConfiguration
	
	for piece: Match3PieceConfiguration in pieces:
		if threshold <= piece.weight.total_accum_weight:
			selected_piece = piece
			break;
	
	return selected_piece
