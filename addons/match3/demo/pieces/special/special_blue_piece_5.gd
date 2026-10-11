class_name SpecialBluePiece extends Match3Piece


func trigger(board: Match3Board) -> Array[Match3Sequence]:
	super.trigger(board)

	var sequence: Match3Sequence = Match3Sequence.new(board.finder.cell_with_pieces_of_shape(&"triangle"), Match3Sequence.Shapes.Special)
	
	return [sequence]
