class_name Match3BoardFinder extends RefCounted


var board: Match3Board


func _init(_board: Match3Board) -> void:
	board = _board


#region Cells
func get_cell(column: int, row: int) -> Match3GridCell:
	if not board.grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= board.grid_cells.size() - 1 and row <= board.grid_cells[0].size() - 1:
			return board.grid_cells[column][row]
			
	return null
	
func get_cell_piece(column: int, row: int) -> Match3Piece:
	var cell: Match3GridCell = get_cell(column, row)
	
	if cell and cell.has_piece():
		return cell.piece
		
	return null

	
func cells_from_row(row: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(row, 0, board.configuration.grid_height - 1):
		for column: int in board.configuration.grid_width:
			cells.append(board.grid_cells[column][row])
			
	
	return cells.filter(_is_usable_cell) if only_usables else cells
	

func cells_from_column(column: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
		
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(column, 0, board.configuration.grid_width - 1):
		for row: int in board.configuration.grid_height:
			cells.append(board.grid_cells[column][row])
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	
func top_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_top_border():
		return []
	
	while current_cell.neighbour_up != null:
		current_cell = current_cell.neighbour_up
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	

func bottom_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_bottom_border():
		return []
	
	while current_cell.neighbours()["bottom"] != null:
		current_cell = current_cell.neighbours()["bottom"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	

func right_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_right_border():
		return []
	
	while current_cell.neighbours()["right"] != null:
		current_cell = current_cell.neighbours()["right"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells


func left_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_left_border():
		return []
	
	while current_cell.neighbours()["left"] != null:
		current_cell = current_cell.neighbours()["left"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	
func diagonal_top_right_cells_from(cell: Match3GridCell, distance: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = maxi(0, distance)
	var current_cell = cell.diagonal_neighbour_top_right
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array([current_cell] + diagonal_top_right_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func diagonal_top_left_cells_from(cell: Match3GridCell, distance: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = maxi(0, distance)
	var current_cell = cell.diagonal_neighbour_top_left
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array([current_cell] + diagonal_top_left_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells



func diagonal_bottom_left_cells_from(cell: Match3GridCell, distance: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = maxi(0, distance)
	var current_cell = cell.diagonal_neighbour_bottom_left
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array([current_cell] + diagonal_bottom_left_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func diagonal_bottom_right_cells_from(cell: Match3GridCell, distance: int, only_usables: bool = false) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = maxi(0, distance)
	var current_cell = cell.diagonal_neighbour_bottom_right
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array([current_cell] + diagonal_bottom_right_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func adjacent_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Dictionary:
	return origin_cell.usable_neighbours() if only_usables else origin_cell.neighbours()


func cross_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var cross_cells:  Array[Match3GridCell] = []
	
	cross_cells.assign(Match3BoardPluginUtilities.remove_duplicates(
		cells_from_row(origin_cell.row, only_usables) + cells_from_column(origin_cell.column, only_usables)
		))
	
	return cross_cells


func cross_diagonal_cells_from(origin_cell: Match3GridCell, only_usables: bool = false) -> Array[Match3GridCell]:
	var distance: int = board.distance()
	var cross_diagonal_cells: Array[Match3GridCell] = []
	
	cross_diagonal_cells.assign(Match3BoardPluginUtilities.remove_falsy_values(
		Match3BoardPluginUtilities.remove_duplicates(
		  	diagonal_top_left_cells_from(origin_cell, distance, only_usables)\
		 	+ diagonal_top_right_cells_from(origin_cell, distance, only_usables)\
			+ diagonal_bottom_left_cells_from(origin_cell, distance, only_usables)\
		 	+ diagonal_bottom_right_cells_from(origin_cell, distance, only_usables)\
		)))
	
	return cross_diagonal_cells


func empty_cells() -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(board.grid_cells_flattened.filter(_is_empty_cell))
	
	return cells
	
	
func cell_with_pieces_of_id(id: StringName) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(pieces_of_id(id).map(func(piece: Match3Piece): return piece.cell))
	
	return cells
	
	
func cell_with_pieces_of_shape(shape: StringName) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(pieces_of_shape(shape).map(func(piece: Match3Piece): return piece.cell))
	
	return cells


func cell_with_pieces_of_type(type: Match3PieceConfiguration.PieceType) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(pieces_of_type(type).map(func(piece: Match3Piece): return piece.cell))
	
	return cells


func cell_with_pieces_of_color(color: Match3PieceConfiguration.PieceType) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(pieces_of_color(color).map(func(piece: Match3Piece): return piece.cell))
	
	return cells


func pieces() -> Array[Match3Piece]:
	var pieces: Array[Match3Piece] = []
	pieces.assign(board.get_tree().get_nodes_in_group(Match3Piece.GroupName))

	return pieces
	

func special_pieces() -> Array[Match3Piece]:
	var pieces: Array[Match3Piece] = []
	pieces.assign(board.get_tree().get_nodes_in_group(Match3Piece.SpecialGroupName))

	return pieces


func obstacle_pieces() -> Array[Match3Piece]:
	var pieces: Array[Match3Piece] = []
	pieces.assign(board.get_tree().get_nodes_in_group(Match3Piece.ObstacleGroupName))

	return pieces


func pieces_of_id(id: StringName) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	result.assign(pieces().filter(func(piece: Match3Piece): return piece.id == id))
	
	return result


func pieces_of_shape(shape: StringName) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	result.assign(pieces().filter(func(piece: Match3Piece): return piece.shape == shape))
	
	return result


func pieces_of_type(type: Match3PieceConfiguration.PieceType) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	
	match type:
		Match3PieceConfiguration.PieceType.Normal:
			result.assign(board.get_tree().get_nodes_in_group(Match3Piece.GroupName))
		Match3PieceConfiguration.PieceType.Special:
			result.assign(board.get_tree().get_nodes_in_group(Match3Piece.SpecialGroupName))
		Match3PieceConfiguration.PieceType.Obstacle:
			result.assign(board.get_tree().get_nodes_in_group(Match3Piece.ObstacleGroupName))
			
	return result


func pieces_of_color(color: Color) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	result.assign(pieces().filter(func(piece: Match3Piece): return piece.color.is_equal_approx(color)))
	
	return result
	

func _is_empty_cell(cell: Match3GridCell) -> bool:
	return cell.can_contain_piece and cell.is_empty()


func _is_usable_cell(cell: Match3GridCell) -> bool:
	return cell.can_contain_piece and not cell.is_empty()
	
#region Pieces
	
func pieces_from_row(row: int) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	
	result.assign(cells_from_row(row).filter(func(cell: Match3GridCell): return cell.has_piece())\
		.map(func(cell: Match3GridCell): return cell.piece))
	
	return result


func pieces_from_column(column: int) -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	
	result.assign(cells_from_column(column).filter(func(cell: Match3GridCell): return cell.has_piece())\
		.map(func(cell: Match3GridCell): return cell.piece))
		
	return result
#endregion
