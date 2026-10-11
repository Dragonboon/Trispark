class_name Match3FallMover extends RefCounted
## Computes a stable gravity plan without changing the live board.
## Column/row coordinates, not scene positions, determine the fall direction.

var board: Match3Board

func _init(owner: Match3Board) -> void:
	board = owner


func fall_pieces() -> Array[FallMovement]:
	var result: Array[FallMovement] = []
	if board.configuration.fill_mode_is_in_place():
		return result
	var occupied: Dictionary = {}
	var origins: Dictionary = {}
	var pieces: Array[Match3Piece] = []
	for cell in board.grid_cells_flattened:
		if cell.has_piece():
			occupied[cell.board_position()] = cell.piece
			origins[cell.piece] = cell
			pieces.append(cell.piece)
	var height := board.configuration.grid_height
	var width := board.configuration.grid_width
	# Each pass moves pieces at most one row, so height passes suffice.
	for _pass in range(height):
		var moved := false
		for row in range(height - 2, -1, -1):
			for column in range(width):
				var source_pos := Vector2i(column, row)
				var piece: Match3Piece = occupied.get(source_pos)
				if piece == null or not piece.can_be_moved:
					continue
				var destination := Vector2i(column, row + 1)
				if not _can_enter(destination, occupied):
					if not board.configuration.fill_mode_is_side():
						continue
					# A blocked vertical fall can slide to an open diagonal.
					var right := Vector2i(column + 1, row + 1)
					var left := Vector2i(column - 1, row + 1)
					if _can_enter(right, occupied):
						destination = right
					elif _can_enter(left, occupied):
						destination = left
					else:
						continue
				occupied.erase(source_pos)
				occupied[destination] = piece
				moved = true
		if not moved:
			break
	for position in occupied:
		var piece: Match3Piece = occupied[position]
		var origin: Match3GridCell = origins[piece]
		var target: Match3GridCell = board.finder.get_cell(position.x, position.y)
		if target != origin:
			result.append(FallMovement.new(origin, target, piece))
	return result


func _can_enter(position: Vector2i, occupied: Dictionary) -> bool:
	var cell := board.finder.get_cell(position.x, position.y)
	return cell != null and cell.can_contain_piece and not occupied.has(position)


func calculate_fall_movements_on_column(column: int) -> Array[FallMovement]:
	var result: Array[FallMovement] = []
	for movement in fall_pieces():
		if movement.from_cell.column == column:
			result.append(movement)
	return result


func pieces_can_fall_in_column(column: int) -> bool:
	return not calculate_fall_movements_on_column(column).is_empty()


class FallMovement:
	var from_cell: Match3GridCell
	var to_cell: Match3GridCell
	var piece: Match3Piece

	func _init(origin: Match3GridCell, destination: Match3GridCell, moving_piece: Match3Piece) -> void:
		from_cell = origin
		to_cell = destination
		piece = moving_piece

	func is_diagonal() -> bool:
		return from_cell.column != to_cell.column
