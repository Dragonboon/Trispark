class_name Match3Shuffler extends RefCounted


var board: Match3Board


func _init(_board: Match3Board) -> void:
	board = _board


func shuffle() -> Array[ShuffleMovement]:
	var cells: Array[Match3GridCell] = []
	cells.assign(board.pieces()\
		.filter(func(piece: Match3Piece): return piece.can_be_shuffled and piece.cell and is_instance_valid(piece.cell))\
		.map(func(piece: Match3Piece): return piece.cell))
	
	var shuffled_cells: Array[Match3GridCell] = []
	var shuffle_movements: Array[ShuffleMovement] = []
	 
	while cells.size() >= 2:
		cells.shuffle()
		var front_cell: Match3GridCell = cells.pop_front()
		var back_cell: Match3GridCell = cells.pop_back()
		
		shuffle_movements.append(ShuffleMovement.new(front_cell, back_cell))
		shuffled_cells.append_array([front_cell, back_cell])
		
	return shuffle_movements
	

class ShuffleMovement extends RefCounted:
	var from_cell: Match3GridCell
	var to_cell: Match3GridCell
	
	func _init( _from_cell: Match3GridCell, _to_cell: Match3GridCell) -> void:
		assert(_from_cell.has_piece() and _to_cell.has_piece(), "ShuffleMovement: The cells in positions %v and %v does not have a valid piece to shuffle" % [_from_cell.board_position(), _to_cell.board_position()])
		from_cell = _from_cell
		to_cell = _to_cell

	func swap() -> void:
		var from_piece = from_cell.piece
		from_cell.piece = to_cell.piece
		to_cell.piece = from_piece
		from_cell.piece.position = from_cell.position
		to_cell.piece.position = to_cell.position
