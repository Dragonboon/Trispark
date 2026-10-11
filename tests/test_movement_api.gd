extends SceneTree
## Movement mode regression and optional Resource adapter contract.

const CustomMove = preload("res://tests/fixtures/diagonal_jump_adapter.gd")
var board: Match3Board

func _initialize() -> void:
	board = Match3Board.new()
	board.configuration = Match3BoardConfiguration.new()
	board.configuration.grid_width = 5
	board.configuration.grid_height = 5
	for x in range(5):
		board.grid_cells.append([])
		for y in range(5):
			var cell := Match3GridCell.new()
			cell.column = x
			cell.row = y
			var piece := Match3Piece.new()
			piece.id = StringName("%d-%d" % [x, y])
			piece.shape = piece.id
			cell.piece = piece
			board.grid_cells[x].append(cell)
			board.grid_cells_flattened.append(cell)
	board._update_grid_cells_neighbours()
	var center := board.get_cell(2, 2)
	var modes := {
		Match3BoardConfiguration.BoardMovements.Adjacent: 4,
		Match3BoardConfiguration.BoardMovements.AdjacentWithDiagonals: 8,
		Match3BoardConfiguration.BoardMovements.AdjacentDiagonals: 4,
		Match3BoardConfiguration.BoardMovements.Free: 24,
		Match3BoardConfiguration.BoardMovements.Row: 4,
		Match3BoardConfiguration.BoardMovements.Column: 4,
		Match3BoardConfiguration.BoardMovements.Cross: 8,
		Match3BoardConfiguration.BoardMovements.CrossDiagonal: 8,
		Match3BoardConfiguration.BoardMovements.ConnectLine: 0,
	}
	for mode in modes:
		board.configuration.swap_mode = mode
		assert(board.get_valid_swap_targets(center).size() == modes[mode], "Wrong move count for mode %s" % mode)
	board.configuration.swap_mode = Match3BoardConfiguration.BoardMovements.Adjacent
	board.get_cell(1, 2).can_contain_piece = false
	assert(board.get_valid_swap_targets(center).size() == 3, "Disabled cell should not be a swap target.")
	board.get_cell(1, 2).can_contain_piece = true
	board.configuration.movement_adapter = CustomMove.new()
	var targets := board.get_valid_swap_targets(center)
	assert(targets.size() == 1 and targets[0] == board.get_cell(4, 4), "Adapter rule not honored.")
	board.configuration.movement_adapter = null
	var special := board.get_cell(4, 4).piece
	special.type = Match3PieceConfiguration.PieceType.Special
	assert(not board.swap_movement_is_valid(center, board.get_cell(4, 4)), "Invalid special move accepted.")
	assert(board.pending_special_pieces.is_empty(), "Invalid swap queued a special piece.")
	print("Match3 movement API regression: PASS")
	quit()
