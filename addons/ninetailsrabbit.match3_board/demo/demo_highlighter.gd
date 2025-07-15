class_name Match3DemoHighlighter extends Match3Highlighter

const highlight_texture = preload("res://addons/ninetailsrabbit.match3_board/demo/assets/highlighted.png")


func highlight_cells(cells: Array[Match3GridCell]) -> void:
	current_highlighted_cells = cells
	
	for cell in current_highlighted_cells:
		highlight_cell(cell)


func highlight_cell(cell: Match3GridCell) -> void:
	cell.sprite_2d.texture = highlight_texture


func remove_highlight() -> void:
	for cell in current_highlighted_cells:
		if cell.sprite_2d and cell.sprite_2d is Sprite2D:
			cell.sprite_2d.texture = cell.original_texture
		
	current_highlighted_cells.clear()

	for piece in current_highlighted_pieces:
		pass
		
	current_highlighted_pieces.clear()


func on_selected_piece(piece: Match3Piece) -> void:
	if piece.is_special() and piece.can_be_triggered:
		return
	
	remove_highlight()
	
	var cell: Match3GridCell = piece.cell
	var neighbours: Dictionary = cell.usable_neighbours()
	var target_cells: Array[Match3GridCell] = []
	
	match board.configuration.swap_mode:
		Match3BoardConfiguration.BoardMovements.Adjacent:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([neighbours.up, neighbours.bottom, neighbours.left, neighbours.right]))
			
		Match3BoardConfiguration.BoardMovements.AdjacentWithDiagonals:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([
				neighbours.up, neighbours.bottom, neighbours.left, neighbours.right,
				neighbours.diagonal_bottom_right, neighbours.diagonal_bottom_left, neighbours.diagonal_top_left, neighbours.diagonal_top_right
				]))
			
		Match3BoardConfiguration.BoardMovements.AdjacentDiagonals:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([
				neighbours.diagonal_bottom_right, neighbours.diagonal_bottom_left, neighbours.diagonal_top_left, neighbours.diagonal_top_right
			]))
			
		Match3BoardConfiguration.BoardMovements.Free:
			target_cells.append(cell)
			
		Match3BoardConfiguration.BoardMovements.Row:
			target_cells.append_array(board.finder.cells_from_row(cell.row, true))
			
		Match3BoardConfiguration.BoardMovements.Column:
			target_cells.append_array(board.finder.cells_from_column(cell.column, true))
			
		Match3BoardConfiguration.BoardMovements.Cross:
			target_cells.append_array(board.finder.cross_cells_from(cell, true))
			
		Match3BoardConfiguration.BoardMovements.CrossDiagonal:
			target_cells.append_array(board.finder.cross_diagonal_cells_from(cell, true))
			
		Match3BoardConfiguration.BoardMovements.ConnectLine:
			pass ## This swap mode is handled on the on_connected_piece signal callback
			
	highlight_cells(target_cells)


func on_connected_piece(piece: Match3Piece) -> void:
	if board.configuration.swap_mode_is_connect_line():
		remove_highlight()
		
		if board.line_connector.can_connect_more_pieces():
			var valid_cells: Array[Match3GridCell] = board.line_connector.matches_from_piece(piece)
			highlight_cells(valid_cells)
			current_highlighted_cells.append_array(valid_cells)
