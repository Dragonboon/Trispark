extends SceneTree
## Regression: signal compatibility, contextual events, opt-in Resource reactions.
const Receiver = preload("res://tests/fixtures/event_receiver.gd")

var observed: Array[Match3BoardEvent] = []


func _initialize() -> void:
	var host := Node2D.new()
	get_root().add_child(host)
	var receiver := Node.new()
	receiver.set_script(Receiver)
	receiver.name = "HUD"
	host.add_child(receiver)

	var board := Match3Board.new()
	board.configuration = Match3BoardConfiguration.new()
	board.configuration.auto_start = false
	board.configuration.available_moves_on_start = 8

	var method_reaction := Match3CallMethodReaction.new()
	method_reaction.target_path = NodePath("../HUD")
	method_reaction.method_name = &"on_event"
	method_reaction.event_mask = Match3Reaction.mask_for(Match3BoardEvent.Type.SWAP_REJECTED)
	board.configuration.event_reactions.append(method_reaction)

	var simple_reaction := Match3CallMethodReaction.new()
	simple_reaction.target_path = NodePath("../HUD")
	simple_reaction.method_name = &"on_simple_event"
	simple_reaction.pass_event = false
	simple_reaction.event_mask = Match3Reaction.mask_for(Match3BoardEvent.Type.SWAP_REJECTED)
	board.configuration.event_reactions.append(simple_reaction)

	board.event_emitted.connect(_on_event)
	host.add_child(board)
	call_deferred("_verify", board, receiver, host)


func _on_event(event: Match3BoardEvent) -> void:
	observed.append(event)


func _verify(board: Match3Board, receiver: Node, host: Node2D) -> void:
	var first := Match3GridCell.new()
	first.column = 1
	first.row = 2
	var second := Match3GridCell.new()
	second.column = 2
	second.row = 2

	board.swap_rejected.emit(first, second)
	assert(observed.size() == 1 and observed[0].type == Match3BoardEvent.Type.SWAP_REJECTED)
	assert(observed[0].board == board and observed[0].cell == first and observed[0].other_cell == second)
	assert(receiver.received.size() == 1, "Filtered method reaction should fire.")
	assert(receiver.simple_calls == 1, "No-argument method callback did not fire.")

	board.swap_accepted.emit(first, second)
	assert(observed.size() == 2 and observed[1].type == Match3BoardEvent.Type.SWAP_ACCEPTED)
	assert(receiver.received.size() == 1, "Filtered reaction ran on another event.")

	board.current_available_moves = 8
	board.current_available_moves = 7
	assert(observed.back().type == Match3BoardEvent.Type.MOVE_CONSUMED)
	assert(observed.back().moves_remaining == 7)

	var piece := Match3Piece.new()
	board.selected_piece.emit(piece)
	assert(observed.back().type == Match3BoardEvent.Type.PIECE_SELECTED)
	assert(observed.back().piece == piece)

	var seq_cells: Array[Match3GridCell] = [first, second, Match3GridCell.new()]
	for cell in seq_cells:
		cell.piece = Match3Piece.new()
	var seq := Match3Sequence.new(seq_cells, Match3Sequence.Shapes.Horizontal)
	board.consumed_sequence.emit(seq)
	assert(observed.back().type == Match3BoardEvent.Type.SEQUENCE_CONSUMED)
	assert(observed.back().sequence == seq)
	assert(Match3Reaction.mask_for(Match3BoardEvent.Type.SWAP_REJECTED) == (1 << 10))
	print("Match3 events and reactions regression: PASS")
	host.free()
	quit()
