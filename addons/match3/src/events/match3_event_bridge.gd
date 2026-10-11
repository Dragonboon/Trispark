extends RefCounted
## Private, signal-based adapter between the legacy board API and Resources.
## Using a separate bridge keeps event plumbing out of the gameplay state machine.

var board


func _init(owner) -> void:
	board = owner
	board.drawed_pieces.connect(_on_pieces_drawn)
	board.drawed_piece.connect(_on_piece_created)
	board.state_changed.connect(_on_state_changed)
	board.selected_piece.connect(_on_piece_selected)
	board.unselected_piece.connect(_on_piece_unselected)
	board.piece_drag_started.connect(_on_piece_drag_started)
	board.piece_drag_ended.connect(_on_piece_drag_finished)
	board.swap_accepted.connect(_on_swap_accepted)
	board.swap_rejected.connect(_on_swap_rejected)
	board.consumed_sequence.connect(_on_sequence_consumed)
	board.shuffle_started.connect(_on_shuffle_started)
	board.shuffle_ended.connect(_on_shuffle_finished)
	board.movement_consumed.connect(_on_move_consumed)
	board.finished_available_movements.connect(_on_out_of_moves)


func track_piece(piece: Match3Piece) -> void:
	var triggered := _on_piece_triggered.bind(piece)
	var queued := _on_piece_queued.bind(piece)
	if not piece.triggered.is_connected(triggered):
		piece.triggered.connect(triggered)
	if not piece.queued.is_connected(queued):
		piece.queued.connect(queued)


func _dispatch(event: Match3BoardEvent) -> void:
	event.board = board
	event.moves_remaining = board.current_available_moves
	if event.cell != null:
		event.world_position = event.cell.global_position
	elif event.piece != null and is_instance_valid(event.piece):
		event.world_position = event.piece.global_position
	board.event_emitted.emit(event)
	if board.configuration == null:
		return
	for reaction: Match3Reaction in board.configuration.event_reactions:
		if reaction != null and reaction.accepts(event):
			reaction.react(board, event)


func _on_pieces_drawn(_pieces: Array[Match3Piece]) -> void:
	_dispatch(Match3BoardEvent.new(Match3BoardEvent.Type.PIECES_DRAWN))


func _on_piece_created(piece: Match3Piece) -> void:
	var event := Match3BoardEvent.new(Match3BoardEvent.Type.PIECE_CREATED)
	event.piece = piece
	event.cell = piece.cell
	_dispatch(event)


func _on_state_changed(previous: int, next: int) -> void:
	var event := Match3BoardEvent.new(Match3BoardEvent.Type.STATE_CHANGED)
	event.previous_state = previous
	event.new_state = next
	_dispatch(event)


func _on_piece_selected(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_SELECTED, piece)


func _on_piece_unselected(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_UNSELECTED, piece)


func _on_piece_drag_started(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_DRAG_STARTED, piece)


func _on_piece_drag_finished(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_DRAG_FINISHED, piece)


func _on_piece_queued(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_QUEUED, piece)


func _on_piece_triggered(piece: Match3Piece) -> void:
	_dispatch_piece(Match3BoardEvent.Type.PIECE_TRIGGERED, piece)


func _dispatch_piece(event_type: Match3BoardEvent.Type, piece: Match3Piece) -> void:
	var event := Match3BoardEvent.new(event_type)
	event.piece = piece
	if is_instance_valid(piece):
		event.cell = piece.cell
	_dispatch(event)


func _on_swap_accepted(from_cell: Match3GridCell, to_cell: Match3GridCell) -> void:
	_dispatch_swap(Match3BoardEvent.Type.SWAP_ACCEPTED, from_cell, to_cell)


func _on_swap_rejected(from_cell: Match3GridCell, to_cell: Match3GridCell) -> void:
	_dispatch_swap(Match3BoardEvent.Type.SWAP_REJECTED, from_cell, to_cell)


func _dispatch_swap(event_type: Match3BoardEvent.Type, from_cell: Match3GridCell, to_cell: Match3GridCell) -> void:
	var event := Match3BoardEvent.new(event_type)
	event.cell = from_cell
	event.other_cell = to_cell
	_dispatch(event)


func _on_sequence_consumed(sequence: Match3Sequence) -> void:
	var event := Match3BoardEvent.new(Match3BoardEvent.Type.SEQUENCE_CONSUMED)
	event.sequence = sequence
	event.cell = sequence.middle_cell()
	_dispatch(event)


func _on_shuffle_started() -> void:
	_dispatch(Match3BoardEvent.new(Match3BoardEvent.Type.SHUFFLE_STARTED))


func _on_shuffle_finished() -> void:
	_dispatch(Match3BoardEvent.new(Match3BoardEvent.Type.SHUFFLE_FINISHED))


func _on_move_consumed() -> void:
	_dispatch(Match3BoardEvent.new(Match3BoardEvent.Type.MOVE_CONSUMED))


func _on_out_of_moves() -> void:
	_dispatch(Match3BoardEvent.new(Match3BoardEvent.Type.OUT_OF_MOVES))
