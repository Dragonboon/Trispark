@tool
class_name Match3MovementAdapter extends Resource
## Optional spatial rule provider. Subclass this Resource for custom swaps.
## This method must be pure: highlighters may query it every selection.
## Standard piece/obstacle validation stays in Match3Board.can_swap_cells().

func allows_swap(_board: Match3Board, _from_cell: Match3GridCell, _to_cell: Match3GridCell) -> bool:
	return false
