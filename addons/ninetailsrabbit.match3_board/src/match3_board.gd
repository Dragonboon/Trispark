class_name Match3Board extends Node2D

const GroupName: StringName = &"match3-board"

signal state_changed(from: BoardState, to: BoardState)
signal swap_accepted(from: Match3GridCell, to: Match3GridCell)
signal swap_rejected(from: Match3GridCell, to: Match3GridCell)
signal consumed_sequence(sequence: Match3Sequence)
signal consumed_sequences(sequences: Array[Match3Sequence])
signal selected_piece(piece: Match3Piece)
signal unselected_piece(piece: Match3Piece)
signal piece_drag_started(piece: Match3Piece)
signal piece_drag_ended(piece: Match3Piece)
signal drawed_cells(cells: Array[Match3GridCell])
signal drawed_cell(cell: Match3GridCell)
signal drawed_piece(piece: Match3Piece)
signal drawed_pieces(pieces: Array[Match3Piece])
signal shuffle_started
signal shuffle_ended
signal locked
signal unlocked
signal movement_consumed
signal finished_available_movements

@export_category("Configuration")
@export var configuration: Match3BoardConfiguration
@export var animator: Match3Animator
@export var highlighter: Match3Highlighter
@export var line_connector: Match3LineConnector

enum BoardState {
	WaitForInput,
	Consume,
	SpecialConsume,
	Fall,
	Fill
}
#
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[Match3GridCell] = []
var finder: Match3BoardFinder = Match3BoardFinder.new(self)
var fall_mover: Match3FallMover = Match3FallMover.new(self)
var filler: Match3Filler = Match3Filler.new(self)
var sequence_detector: Match3SequenceDetector = Match3SequenceDetector.new(self)
var sequence_consumer: Match3SequenceConsumer
var shuffler: Match3Shuffler = Match3Shuffler.new(self)
var piece_generator: Match3PieceGenerator = Match3PieceGenerator.new()

var current_available_moves: int = 0:
	set(value):
		if value != current_available_moves:
			if value == -1:
				current_available_moves = value
				return
				
			var previous_moves: int = current_available_moves
			current_available_moves = clamp(value, 0, configuration.available_moves_on_start)
			
			if value < previous_moves:
				movement_consumed.emit()
			
			elif value == 0:
				finished_available_movements.emit()
			

var pending_special_pieces: Array[Match3Piece] = []
var current_selected_piece: Match3Piece:
	set(new_piece):
		if new_piece != current_selected_piece:
			var previous_piece := current_selected_piece
			current_selected_piece = new_piece
			
			if current_selected_piece == null:
				unselected_piece.emit(previous_piece)
			else:
				selected_piece.emit(current_selected_piece)
	
			
var current_state: BoardState = BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			var previous_state: BoardState = current_state
			current_state = new_state
			state_changed.emit(previous_state, current_state)

var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()


func _enter_tree() -> void:
	add_to_group(GroupName)
	child_entered_tree.connect(on_child_entered_tree)


func _ready() -> void:
	assert(configuration != null, "Match3Board: This board needs a configuration")
	
	if configuration.swap_mode_is_connect_line():
		assert(line_connector != null, "Match3Board: The swap mode ConnectLine needs a line connector in this board")
	
	sequence_consumer = Match3SequenceConsumer.new(self, configuration.sequence_rules)
	current_available_moves = configuration.available_moves_on_start
	
	add_pieces_to_generator(configuration.available_pieces)

	swap_accepted.connect(on_swap_accepted)
	swap_rejected.connect(on_swap_rejected)
	locked.connect(on_board_locked)
	unlocked.connect(on_board_unlocked)
	state_changed.connect(on_board_state_changed)
	drawed_cells.connect(on_drawed_cells)
	drawed_pieces.connect(on_drawed_pieces)
	
	if line_connector:
		line_connector.canceled_match.connect(on_line_connector_canceled_match)
	
	if configuration.auto_start:
		await draw_cells()
		await draw_pieces()
	

func distance() -> int:
	return configuration.grid_width + configuration.grid_height
	

func size() -> int:
	return configuration.grid_width * configuration.grid_height


func travel_to(new_state: BoardState) -> void:
	current_state = new_state


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


#region Draw 
func draw_cells() -> Match3Board:
	if grid_cells.is_empty():
		for column in configuration.grid_width:
			grid_cells.append([])
			
			for row in configuration.grid_height:
				grid_cells[column].append(draw_cell(column, row))
				
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
		_update_grid_cells_neighbours(grid_cells_flattened)
			
			
		if animator:
			if configuration.draw_cells_and_pieces_animation_is_serial():
				await animator.run(Match3Animator.DrawCellsAnimation, [grid_cells_flattened])
			elif configuration.draw_cells_and_pieces_animation_is_parallel():
				animator.run(Match3Animator.DrawCellsAnimation, [grid_cells_flattened])
			
		drawed_cells.emit(grid_cells_flattened)
		
	return self


func draw_cell(column: int, row: int) -> Match3GridCell:
	if grid_cells_flattened.any(func(cell: Match3GridCell): cell.in_same_grid_position_as(Vector2i(column, row))):
		return
		
	var cell: Match3GridCell =  configuration.grid_cell_scene.instantiate()
	cell.size = configuration.cell_size
	cell.column = column
	cell.row = row
	cell.position = Vector2(
		configuration.cell_size.x * cell.column, configuration.cell_size.y * cell.row
		) * cell.texture_scale
	
	cell.position.x += configuration.cell_offset.x * column
	cell.position.y += configuration.cell_offset.y * row
	
	if cell.board_position() in configuration.empty_cells:
		clear_cell(cell, true)
		
	add_child(cell)
	
	drawed_cell.emit(cell)
	
	return cell


func clear_cell(cell: Match3GridCell, disable: bool = false) -> void:
	cell.clear(disable)


func draw_pieces() -> Match3Board:
	assert(configuration.available_pieces.size() > 0, "Match3Board: No available pieces are set for this board, the pieces cannot be drawed")
	
	for cell: Match3GridCell in grid_cells_flattened:
		draw_random_piece_on_cell(cell)
	
	lock_all_pieces()
	
	if animator:
		if configuration.draw_cells_and_pieces_animation_is_serial():
			await animator.run(Match3Animator.DrawPiecesAnimation, [pieces()])
		elif configuration.draw_cells_and_pieces_animation_is_parallel():
			animator.run(Match3Animator.DrawPiecesAnimation, [pieces()])
	
	unlock_all_pieces()
	drawed_pieces.emit(pieces())
	
	return self


func draw_piece_on_cell(cell: Match3GridCell, piece: Match3Piece, replace: bool = false) -> void:
	if cell.can_contain_piece and (cell.is_empty() or replace):
		piece.cell = cell
		piece.position = cell.position
		
		if replace and cell.has_piece():
			cell.remove_piece()
			
		cell.piece = piece
		
		if not piece.is_inside_tree():
			add_child(piece)
			drawed_piece.emit(piece)


func draw_random_piece_on_cell(cell: Match3GridCell, replace: bool = false) -> Match3Piece:
	if cell.can_contain_piece and (cell.is_empty() or replace):
		var piece: Match3Piece = Match3Piece.from_configuration(piece_generator.roll())
		draw_piece_on_cell(cell, piece, replace)
		
		return piece
		
	return null
	
	
func _update_grid_cells_neighbours(cells: Array[Match3GridCell] = grid_cells_flattened) -> void:
	for cell: Match3GridCell in cells:
		cell.neighbour_up = finder.get_cell(cell.column, cell.row - 1)
		cell.neighbour_bottom = finder.get_cell(cell.column, cell.row + 1)
		cell.neighbour_right = finder.get_cell(cell.column + 1, cell.row )
		cell.neighbour_left = finder.get_cell(cell.column - 1, cell.row)
		cell.diagonal_neighbour_top_right = finder.get_cell(cell.column + 1, cell.row - 1)
		cell.diagonal_neighbour_top_left = finder.get_cell(cell.column - 1, cell.row - 1)
		cell.diagonal_neighbour_bottom_right = finder.get_cell(cell.column + 1, cell.row + 1)
		cell.diagonal_neighbour_bottom_left = finder.get_cell(cell.column - 1, cell.row + 1)


func add_pieces_to_generator(pieces: Array[Match3PieceConfiguration]) -> Match3Board:
	for piece_configuration: Match3PieceConfiguration in pieces:
		add_piece_to_generator(piece_configuration)
	
	return self


func add_piece_to_generator(piece_configuration: Match3PieceConfiguration) -> Match3Board:
	assert(not piece_configuration.id.is_empty(), "Match3Board->add_piece: The ID of the piece to add is empty, the piece cannot be added")
	
	piece_generator.add_piece(piece_configuration)
	
	return self

#endregion


#region Pieces
func remove_matches_from_board() -> void:
	var sequences: Array[Match3Sequence] = sequence_detector.find_board_sequences()
	
	while sequences.size() > 0:
		for sequence: Match3Sequence in sequences:
			var cells_to_change = sequence.cells.slice(0, (sequence.cells.size() / configuration.min_match) + 1)
			var piece_exceptions: Array[Match3PieceConfiguration] = []
			
			piece_exceptions.assign(Match3BoardPluginUtilities.remove_duplicates(
				cells_to_change.map(
					func(cell: Match3GridCell): 
						return configuration.available_pieces.filter(
							func(piece_conf: Match3PieceConfiguration): return cell.piece.id == piece_conf.id).front()
							)
					)
				)
			
			for current_cell: Match3GridCell in cells_to_change:
				current_cell.remove_piece()
	
				draw_piece_on_cell(current_cell, Match3Piece.from_configuration(piece_generator.roll(piece_exceptions)))
			
		sequences = sequence_detector.find_board_sequences()


func shuffle() -> void:
	if state_is_wait_for_input():
		lock_all_pieces()
		shuffle_started.emit()
		
		var shuffle_movements := shuffler.shuffle()
		
		if animator:
			await animator.run(Match3Animator.ShufflePiecesAnimation, [shuffle_movements])
			
		for shuffle_movement in shuffle_movements:
			shuffle_movement.swap()
			
		if configuration.delay_after_shuffle > 0:
			await get_tree().create_timer(configuration.delay_after_shuffle).timeout
		
		shuffle_ended.emit()
		travel_to(BoardState.Consume)
		

func pieces() -> Array[Match3Piece]:
	return finder.pieces()
	

func special_pieces() -> Array[Match3Piece]:
	return finder.special_pieces()


func obstacle_pieces() -> Array[Match3Piece]:
	return finder.obstacle_pieces()


func lock_all_pieces() -> void:
	for piece: Match3Piece in pieces():
		piece.lock()

	
func unlock_all_pieces() -> void:
	for piece: Match3Piece in pieces():
		piece.unlock()


func add_special_pieces_to_queue(pieces: Array[Match3Piece]) -> void:
	for piece in pieces:
		add_special_piece_to_queue(piece)


func add_special_piece_to_queue(piece: Match3Piece) -> void:
	if not pending_special_pieces.has(piece) \
		and is_instance_valid(piece) \
		and piece.is_special() \
		and not piece.on_queue \
		and not piece.is_queued_for_deletion():
			piece.on_queue = true
			pending_special_pieces.append(piece)
			

func consume_sequence(sequence: Match3Sequence) -> void:
	if sequence.contains_special_piece():
		for special_piece: Match3Piece in sequence.special_pieces():
			add_special_piece_to_queue(special_piece)
		
	if animator:
		await animator.run(Match3Animator.ConsumeSequenceAnimation, [sequence])
	
	consumed_sequence.emit(sequence)
	sequence.consume()
	await get_tree().process_frame
	
	if pending_special_pieces.is_empty():
		travel_to(BoardState.Fall)
	else:
		travel_to(BoardState.SpecialConsume)
		

func consume_sequences(sequences: Array[Match3Sequence]) -> void:
	var sequences_result: Array[Match3SequenceConsumer.Match3SequenceConsumeResult] = sequence_consumer.sequences_to_combo_rules(sequences)
					
	if animator:
		if configuration.sequence_animation_is_serial():
			for sequence_result in sequences_result:
				for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
					await animator.run(Match3Animator.ConsumeSequenceAnimation, [combo.sequence])
					
		elif configuration.sequence_animation_is_parallel():
			await animator.run(Match3Animator.ConsumeSequencesAnimation, [sequences_result])
		
	for sequence_result in sequences_result:
		for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
			if combo.sequence.contains_special_piece():
				add_special_pieces_to_queue(combo.sequence.special_pieces())
				
			consumed_sequence.emit(combo.sequence.duplicate())
			combo.sequence.consume_normal_cells()
			await get_tree().process_frame
			
			if combo.special_piece_to_spawn:
				var piece: Match3Piece = Match3Piece.from_configuration(combo.special_piece_to_spawn)
				draw_piece_on_cell(piece.spawn(self, combo.sequence), piece)
				piece.is_locked = true
			
	consumed_sequences.emit(sequences)
	
	await get_tree().process_frame
	
	if pending_special_pieces.is_empty():
		travel_to(BoardState.Fall)
	else:
		if state_is_special_consume():
			consume_special_pieces(pending_special_pieces)
		else:
			travel_to(BoardState.SpecialConsume)


func consume_special_pieces(special_pieces: Array[Match3Piece] = pending_special_pieces) -> void:
	if animator:
		var special_animation_callback = func(anim_name: StringName, piece: Match3Piece):
			if anim_name == Match3Animator.TriggerSpecialPieceAnimation:
				pending_special_pieces.erase(piece)
				
				var sequences: Array[Match3Sequence] = piece.trigger(self)
				for sequence in sequences:
					sequence.origin_special_piece = configuration.special_piece_configuration_by_id(piece.id)
				
				consume_sequences(sequences)
				piece.cell.remove_piece(true)
		
		for piece in special_pieces:
			animator.animation_finished.connect(special_animation_callback.bind(piece), CONNECT_ONE_SHOT)
			animator.run(Match3Animator.TriggerSpecialPieceAnimation, [piece])
	else:
		for piece in special_pieces:
			pending_special_pieces.erase(piece)
			
			var sequences: Array[Match3Sequence] = piece.trigger(self)
			for sequence in sequences:
				sequence.origin_special_piece = configuration.special_piece_configuration_by_id(piece.id)
				
			consume_sequences(sequences)
			piece.cell.remove_piece(true)


func fall_pieces() -> void:
	var fall_movements: Array[Match3FallMover.FallMovement] = fall_mover.fall_pieces()
	
	for movement in fall_movements:
		movement.from_cell.piece = null
		movement.to_cell.piece = movement.piece
	
	if animator:
		if configuration.fall_animation_is_serial():
			for movement in fall_movements:
				await animator.run(Match3Animator.FallPieceAnimation, [movement])
		elif configuration.fall_animation_is_parallel():
			await animator.run(Match3Animator.FallPiecesAnimation, [fall_movements])
	else:
		for movement in fall_movements:
			movement.to_cell.piece.position = movement.to_cell.position


func fill_pieces() -> void:
	var filled_cells : Array[Match3GridCell] = filler.fill_empty_cells()
		
	if animator:
		if configuration.fill_animation_is_serial():
			for filled_cell in filled_cells:
				await animator.run(Match3Animator.SpawnPieceAnimation, [filled_cell])
		elif configuration.fill_animation_is_parallel():
			await animator.run(Match3Animator.SpawnPiecesAnimation, [filled_cells])
	
#endregion

#region Swap
func swap_pieces(from_piece: Match3Piece, to_piece: Match3Piece) -> void:
	if configuration.swap_mode_is_connect_line():
		return
		
	var from_cell: Match3GridCell = from_piece.cell
	var to_cell: Match3GridCell = to_piece.cell
	
	if swap_movement_is_valid(from_cell, to_cell):
		lock_all_pieces()
		
		if animator:
			await animator.run(
				Match3Animator.SwapPiecesAnimation, 
				[from_piece, to_piece, to_cell.position, from_cell.position]
				)
		else:
			from_piece.position = to_cell.position
			to_piece.position = from_cell.position
			
		if from_cell.swap_piece_with_cell(to_cell):
			swap_accepted.emit(from_cell, to_cell)
			current_available_moves -= 1
			
			await get_tree().process_frame
			
			if pending_special_pieces.size() > 0:
				travel_to(BoardState.SpecialConsume)
				return
			
			var matches: Array[Match3Sequence] = sequence_detector.find_board_sequences()
					
			if matches.size() > 0:
				travel_to(BoardState.Consume)
			else:
				## Do another swap to return the pieces again
				from_cell.swap_piece_with_cell(to_cell)
				
				if animator:
					## The pieces already come up swapped so we can use the updated original cell position to apply the visual change
					await animator.run(Match3Animator.SwapRejectedPiecesAnimation, [
						from_piece, 
						to_piece, 
						from_cell.position,
						to_cell.position])
				else:
					from_piece.position = from_cell.position
					to_piece.position = to_cell.position
				
				
				swap_rejected.emit(from_cell, to_cell)
	else:
		swap_rejected.emit(from_cell, to_cell)
			

func swap_movement_is_valid(from_cell: Match3GridCell, to_cell: Match3GridCell) -> bool:
	if not from_cell.can_swap_piece_with_cell(to_cell):
		return false
		
	elif not from_cell.piece.is_special() and not to_cell.piece.is_special() and from_cell.piece.match_with(to_cell.piece):
		return false
	
	elif from_cell.piece.is_special() and to_cell.piece.is_special():
		if not _swap_positions_allowed(from_cell, to_cell):
			return false
		add_special_pieces_to_queue([from_cell.piece, to_cell.piece])
		return true
		
	elif from_cell.piece.is_special() and not to_cell.piece.is_special():
		if not _swap_positions_allowed(from_cell, to_cell):
			return false
		add_special_piece_to_queue(from_cell.piece)
		return true
		
	elif not from_cell.piece.is_special() and to_cell.piece.is_special():
		if not _swap_positions_allowed(from_cell, to_cell):
			return false
		add_special_piece_to_queue(to_cell.piece)
		return true
	
	return _swap_positions_allowed(from_cell, to_cell)


func _swap_positions_allowed(from_cell: Match3GridCell, to_cell: Match3GridCell) -> bool:
	match configuration.swap_mode:
		Match3BoardConfiguration.BoardMovements.Adjacent:
			return from_cell.is_adjacent_to(to_cell)
			
		Match3BoardConfiguration.BoardMovements.AdjacentWithDiagonals:
			return from_cell.is_diagonal_adjacent_to(to_cell)
			
		Match3BoardConfiguration.BoardMovements.AdjacentDiagonals:
			return from_cell.in_diagonal_with(to_cell)
			
		Match3BoardConfiguration.BoardMovements.Free:
			return true
			
		Match3BoardConfiguration.BoardMovements.Row:
			return from_cell.in_same_row_as(to_cell)
			
		Match3BoardConfiguration.BoardMovements.Column:
			return from_cell.in_same_column_as(to_cell)
			
		Match3BoardConfiguration.BoardMovements.Cross:
			return finder.cross_cells_from(from_cell).has(to_cell)
			
		Match3BoardConfiguration.BoardMovements.CrossDiagonal:
			return finder.cross_diagonal_cells_from(from_cell).has(to_cell)
		_:
			return false
			
			
func state_is_wait_for_input() -> bool:
	return current_state == BoardState.WaitForInput
	
func state_is_consume() -> bool:
	return current_state == BoardState.Consume
	
func state_is_special_consume() -> bool:
	return current_state == BoardState.SpecialConsume
	
func state_is_fall() -> bool:
	return current_state == BoardState.Fall
	
func state_is_fill() -> bool:
	return current_state == BoardState.Fill
#endregion
#
#
#region Signal callbacks 
func on_child_entered_tree(child: Node) -> void:
	if child is Match3Piece:
		if not child.selected.is_connected(on_selected_piece.bind(child)):
			child.selected.connect(on_selected_piece.bind(child))
		
		if not child.drag_started.is_connected(on_piece_drag_started.bind(child)):
			child.drag_started.connect(on_piece_drag_started.bind(child))
			
		if not child.drag_ended.is_connected(on_piece_drag_ended.bind(child)):
			child.drag_ended.connect(on_piece_drag_ended.bind(child))


func on_drawed_cells(cells: Array[Match3GridCell]) -> void:
		if not configuration.auto_start:
			await draw_cells()


func on_drawed_pieces(pieces: Array[Match3Piece]) -> void:
	if configuration.allow_matches_on_start:
		if not configuration.auto_start:
			await draw_pieces()
		
		travel_to(BoardState.Consume)
	else:
		remove_matches_from_board()
		
		if not configuration.auto_start:
			await draw_pieces()


func on_board_locked() -> void:
	if is_inside_tree():
		lock_all_pieces()


func on_board_unlocked() -> void:
	if is_inside_tree():
		unlock_all_pieces()


func on_line_connector_canceled_match(_pieces: Array[Match3Piece]) -> void:
	current_selected_piece = null
	unlock()


func on_selected_piece(piece: Match3Piece) -> void:
	if current_selected_piece == null and piece.is_special() and piece.can_be_triggered:
		add_special_piece_to_queue(piece)
		travel_to(BoardState.SpecialConsume)
		
	elif configuration.swap_mode_is_connect_line():
		current_selected_piece = piece
		
		if configuration.is_selection_drag_mode() or configuration.is_selection_slide_mode():
			current_selected_piece.drag_started.emit()
			
		lock()
	
	elif configuration.is_selection_click_mode() and not is_locked:
		if current_selected_piece == null:
			current_selected_piece = piece
		
		elif current_selected_piece == piece:
			current_selected_piece = null
		elif current_selected_piece and current_selected_piece != piece:
			swap_pieces(current_selected_piece, piece)
			
			current_selected_piece = null
		

func on_piece_drag_started(piece: Match3Piece) -> void:
	if current_selected_piece == null and piece.is_special() and piece.can_be_triggered:
		add_special_piece_to_queue(piece)
		travel_to(BoardState.SpecialConsume)
		
	elif configuration.swap_mode_is_connect_line():
		current_selected_piece = piece
		
		if configuration.is_selection_drag_mode() or configuration.is_selection_slide_mode():
			piece_drag_started.emit(current_selected_piece)
			
		lock()
		
	elif (configuration.is_selection_drag_mode() or configuration.is_selection_slide_mode()) and not is_locked:
		current_selected_piece = piece
		current_selected_piece.enable_drag(piece.detection_area if configuration.is_selection_slide_mode() else piece)
			
		piece_drag_started.emit(current_selected_piece)


func on_piece_drag_ended(piece: Match3Piece) -> void:
	if configuration.swap_mode_is_connect_line():
		if configuration.is_selection_drag_mode() or configuration.is_selection_slide_mode():
			piece_drag_ended.emit(piece)
			current_selected_piece = null

	elif (configuration.is_selection_drag_mode() or configuration.is_selection_slide_mode()) and current_selected_piece == piece:
		var other_piece = piece.detect_near_piece()
		
		piece.disable_drag()
		
		if other_piece:
			swap_pieces(piece, other_piece)
		else:
			if piece.reset_position_on_drag_release:
				if animator:
					await animator.run(Match3Animator.PieceDragEndedAnimation, [piece])
			
				piece.reset_drag_position()
			
		piece_drag_ended.emit(piece)
		current_selected_piece = null
		

func on_swap_accepted(_from: Match3GridCell, _to: Match3GridCell) -> void:
	lock()


func on_swap_rejected(from: Match3GridCell, _to: Match3GridCell) -> void:
	if configuration.is_selection_drag_mode():
		if animator and from.piece.reset_position_on_drag_release:
			await animator.run(Match3Animator.PieceDragEndedAnimation, [from.piece])

	unlock()
	

func on_board_state_changed(_from: BoardState, to: BoardState) -> void:
	match to:
		BoardState.WaitForInput:
			unlock()
			
		BoardState.Consume:
			lock()
			await consume_sequences(sequence_detector.find_board_sequences())
		BoardState.SpecialConsume:
			lock()
			if pending_special_pieces.is_empty():
				travel_to(BoardState.Fall)
			else:
				consume_special_pieces(pending_special_pieces)
			
		BoardState.Fall:
			lock()
			await fall_pieces()
			await get_tree().process_frame
			
			travel_to(BoardState.Fill)
			
		BoardState.Fill:
			lock()
			await fill_pieces()
			await get_tree().process_frame
			
			if sequence_detector.find_board_sequences().is_empty():
				travel_to(BoardState.WaitForInput)
			else:
				travel_to(BoardState.Consume)
		
					
func on_animator_animation_started(_animation_name: StringName) -> void:
	lock()

#endregion
