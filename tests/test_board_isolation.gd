extends SceneTree
## Multiple live boards must keep queries, locks and movement inside their own grid.

class LogicalPiece extends Match3Piece:
	func _ready() -> void:
		pass
	func _prepare_sprite() -> void:
		pass

class DelayedAnimator extends Match3Animator:
	var swap_calls: int = 0
	func swap_pieces(_from: Match3Piece, _to: Match3Piece, _from_position: Vector2, _to_position: Vector2) -> void:
		swap_calls += 1
		await get_tree().process_frame

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func make_board() -> Match3Board:
	var board: Match3Board = Match3Board.new()
	board.configuration = Match3BoardConfiguration.new()
	board.configuration.auto_start = false
	board.configuration.grid_width = 3
	board.configuration.grid_height = 3
	root.add_child(board)
	for x: int in range(3):
		board.grid_cells.append([])
		for y: int in range(3):
			var cell: Match3GridCell = Match3GridCell.new()
			cell.column = x
			cell.row = y
			board.add_child(cell)
			var piece: LogicalPiece = LogicalPiece.new()
			piece.id = StringName("%d-%d" % [x, y])
			piece.shape = piece.id
			cell.piece = piece
			board.add_child(piece)
			board.grid_cells[x].append(cell)
			board.grid_cells_flattened.append(cell)
	board._update_grid_cells_neighbours()
	return board

func _run() -> void:
	var first: Match3Board = make_board()
	var second: Match3Board = make_board()
	check(first.pieces().size() == 9 and second.pieces().size() == 9, "Piece queries must be local to each board.")
	first.lock_all_pieces()
	check(not second.get_cell(0, 0).piece.is_locked, "Locking one board must not lock another.")
	first.unlock_all_pieces()
	check(not first.can_swap_cells(first.get_cell(0, 0), second.get_cell(1, 0)), "Foreign cells cannot be swap targets.")
	first.set_interaction_enabled(false)
	first.unlock()
	check(not first.is_interaction_enabled(), "Internal unlock must not dismiss a host pause.")
	check(first.get_cell(0, 0).piece.is_locked, "Host pause must still lock pieces after internal unlock.")
	var animator: Match3Animator = Match3Animator.new()
	second.add_child(animator)
	check(animator.board == second, "Child animator must resolve its own board, not the first board.")
	var highlighter: Match3Highlighter = Match3Highlighter.new()
	second.add_child(highlighter)
	check(highlighter.board == second, "Highlighter must resolve its ancestor.")
	var connector: Match3LineConnector = Match3LineConnector.new()
	second.add_child(connector)
	check(connector.board == second, "Line connector must resolve its ancestor.")
	connector.add_piece(first.get_cell(0, 0).piece)
	check(connector.pieces_connected.is_empty(), "Line connection refuses foreign pieces.")
	var orphan: Node = Node.new()
	root.add_child(orphan)
	check(Match3Board.resolve_for(orphan) == null, "Ambiguous global fallback must not choose a random board.")
	check(Match3Board.resolve_for(animator, first) == first, "Explicit assignment wins over ancestry.")
	orphan.free()

	first.get_cell(0, 0).piece.type = Match3PieceConfiguration.PieceType.Special
	second.get_cell(0, 0).piece.type = Match3PieceConfiguration.PieceType.Obstacle
	check(first.special_pieces().size() == 1 and second.special_pieces().is_empty(), "Special queries use current local types.")
	check(first.obstacle_pieces().is_empty() and second.obstacle_pieces().size() == 1, "Obstacle queries stay local.")
	check(first.finder.pieces_of_type(Match3PieceConfiguration.PieceType.Normal).size() == 8, "Normal query excludes specials.")
	first.get_cell(0, 0).piece.color = Color.RED
	check(first.finder.cell_with_pieces_of_color(Color.RED) == [first.get_cell(0, 0)], "Color cell query accepts Color and stays local.")
	check(first.get_valid_swap_targets(second.get_cell(1, 1)).is_empty(), "Foreign origins cannot query this board's targets.")

	first.lock()
	first.set_interaction_enabled(true)
	check(not first.is_interaction_enabled(), "Host resume must not release an internal gameplay lock.")
	first.unlock()
	check(first.is_interaction_enabled(), "Host and gameplay permissions combine when both allow input.")
	root.remove_child(first)
	root.add_child(first)
	check(first.pieces().size() == 9, "Reattaching preserves the logical session.")

	var delayed: DelayedAnimator = DelayedAnimator.new()
	first.add_child(delayed)
	first.animator = delayed
	var from_piece: Match3Piece = first.get_cell(1, 0).piece
	var to_piece: Match3Piece = first.get_cell(2, 0).piece
	first.swap_pieces(from_piece, to_piece)
	check(first.is_locked, "Swap must lock before animation yields.")
	first.swap_pieces(from_piece, to_piece)
	check(delayed.swap_calls == 1, "Concurrent calls must not start a second swap animation.")
	first.set_interaction_enabled(false)
	for frame: int in range(5):
		await process_frame
	check(not first.is_interaction_enabled(), "Rejected swap completion must retain host pause.")
	check(first.get_cell(1, 0).piece == from_piece, "Rejected swap must restore the original grid.")
	check(from_piece.is_locked, "Piece remains locked after in-flight operation finishes.")
	first.set_interaction_enabled(true)
	check(first.is_interaction_enabled() and not from_piece.is_locked, "Resuming an idle board restores input.")
	first.free()
	second.free()
	await process_frame
	if failures == 0:
		print("Match3 board isolation regression: PASS")
	quit(0 if failures == 0 else 1)
