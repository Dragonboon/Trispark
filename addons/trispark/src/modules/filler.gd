class_name Match3Filler extends RefCounted


var board: Match3Board


func _init(_board: Match3Board) -> void:
	board = _board


func fill_empty_cells() -> Array[Match3GridCell]:
	var empty_cells: Array[Match3GridCell] = board.finder.empty_cells()
	var last_pieces: Array[Match3Piece] = []
	
	for cell: Match3GridCell in empty_cells:
		last_pieces.append(board.draw_random_piece_on_cell(cell))
		
		if last_pieces.size() >= board.configuration.min_match:
			while last_pieces.all(func(piece: Match3Piece): return piece.match_with(cell.piece)):
				last_pieces.erase(last_pieces.back())
				last_pieces.append(board.draw_random_piece_on_cell(cell, true))
			
			last_pieces.clear()
			
	return empty_cells
