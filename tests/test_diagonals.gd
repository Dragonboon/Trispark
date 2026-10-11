extends SceneTree
## Headless regression for diagonal runs and stable lateral gravity.

var board: Match3Board

func _initialize() -> void:
	board = Match3Board.new()
	board.configuration = Match3BoardConfiguration.new()
	board.configuration.grid_width = 5
	board.configuration.grid_height = 5
	board.configuration.diagonal_shape = true
	board.configuration.horizontal_shape = false
	board.configuration.vertical_shape = false
	for x in range(5):
		board.grid_cells.append([])
		for y in range(5):
			var cell := Match3GridCell.new()
			cell.column = x
			cell.row = y
			board.grid_cells[x].append(cell)
			board.grid_cells_flattened.append(cell)
	board._update_grid_cells_neighbours()
	for i in range(5):
		place(i, i, &"blue")
	assert(board.get_matches().size() == 1, "Must detect down-right diagonal.")
	assert(board.get_matches()[0].size() == 5, "Long runs must remain intact.")
	clear_pieces()
	for i in range(3):
		place(i, 4 - i, &"blue")
	assert(board.get_matches().size() == 1, "Must detect up-right diagonal.")
	assert(board.get_matches()[0].shape == Match3Sequence.Shapes.Diagonal)
	clear_pieces()
	for i in range(3):
		place(i, i, &"blue")
	board.get_cell(1, 1).can_contain_piece = false
	assert(board.get_matches().is_empty(), "Holes must break diagonal runs.")
	board.get_cell(1, 1).can_contain_piece = true
	clear_pieces()
	board.configuration.fill_mode = Match3BoardConfiguration.BoardFillModes.Side
	place(2, 1, &"falling")
	place(2, 2, &"fixed").can_be_moved = false
	var plan := board.fall_mover.fall_pieces()
	assert(plan.size() == 1, "Lateral fall must generate one stable move.")
	assert(plan[0].from_cell == board.get_cell(2, 1))
	assert(plan[0].to_cell.column != 2, "Blocked downward path should move diagonally.")
	assert(board.get_cell(2, 1).has_piece(), "Planning must not mutate the board.")
	print("Match3 diagonal/gravity regression: PASS")
	clear_pieces()
	for cell: Match3GridCell in board.grid_cells_flattened:
		cell.free()
	board.free()
	quit()


func place(x: int, y: int, id: StringName) -> Match3Piece:
	var piece := Match3Piece.new()
	piece.id = id
	piece.shape = id
	piece.color = Color.BLUE if id == &"blue" else Color.RED
	board.get_cell(x, y).piece = piece
	return piece


func clear_pieces() -> void:
	for cell in board.grid_cells_flattened:
		if cell.piece:
			cell.piece.free()
			cell.piece = null
