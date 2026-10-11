class_name SpecialBluePiece5 extends Match3Piece


func trigger(board: Match3Board) -> Array[Match3Sequence]:
	super.trigger(board)
	
	var sequence: Match3Sequence = Match3Sequence.new(board.finder.cross_cells_from(cell, true), Match3Sequence.Shapes.Special)

	return [sequence]
