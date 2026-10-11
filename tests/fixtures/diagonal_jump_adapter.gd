extends Match3MovementAdapter
## Illustrative pure, reusable Resource adapter: only a jump from center to corner.

func allows_swap(_board: Match3Board, from_cell: Match3GridCell, to_cell: Match3GridCell) -> bool:
	return from_cell.board_position() == Vector2i(2, 2) and to_cell.board_position() == Vector2i(4, 4)
