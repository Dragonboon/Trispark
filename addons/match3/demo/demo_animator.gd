class_name Match3DemoAnimator extends Match3Animator


func swap_pieces(
	from_piece: Match3Piece,
	to_piece: Match3Piece,
	from_piece_target_position: Vector2,
 	to_piece_target_position: Vector2
	):
	
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(from_piece, "position", from_piece_target_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(from_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "position", to_piece_target_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.chain()
	
	tween.tween_property(from_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(to_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	
func swap_rejected_pieces(from_piece: Match3Piece,
	to_piece: Match3Piece,
	from_piece_target_position: Vector2,
	to_piece_target_position: Vector2
):
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(from_piece, "position", from_piece_target_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(from_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "position", to_piece_target_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.chain()
	
	tween.tween_property(from_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(to_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	
func consume_sequence(sequence: Match3Sequence) -> void:
	var pieces: Array[Match3Piece] = sequence.normal_pieces()
	
	if pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece_ui: Match3Piece in pieces:
			tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	

func consume_sequences(sequences: Array[Match3SequenceConsumer.Match3SequenceConsumeResult]) -> void:
	if sequences.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for sequence: Match3SequenceConsumer.Match3SequenceConsumeResult in sequences:
			for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence.combos:
				var pieces: Array[Match3Piece] = combo.sequence.normal_pieces()
				
				for piece_ui: Match3Piece in pieces:
					tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	

func fall_piece(movement: Match3FallMover.FallMovement) -> void:
	if is_instance_valid(movement.piece) and is_instance_valid(movement.to_cell):
		var tween: Tween = create_tween()
		
		tween.tween_property(movement.piece, "position", movement.to_cell.position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			
		await tween.finished
	

func fall_pieces(movements: Array[Match3FallMover.FallMovement]) -> void:
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement in movements:
			if is_instance_valid(movement.piece) and is_instance_valid(movement.to_cell):
				tween.tween_property(movement.piece, "position", movement.to_cell.position, 0.2)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
				
		await tween.finished


## The fill mode selects the visual origin, independently of the filler logic.
## InPlace pieces are already at their destination; reveal them without moving.
func spawn_piece(cell: Match3GridCell) -> void:
	if cell == null or not cell.has_piece():
		return

	if board.configuration.fill_mode_is_in_place():
		var cells: Array[Match3GridCell] = [cell]
		await _spawn_in_place(cells)
		return

	var tween: Tween = create_tween()
	var fall_distance: float = board.configuration.cell_size.y * board.configuration.grid_height

	cell.piece.hide()
	tween.tween_property(cell.piece, "visible", true, 0.1)
	tween.tween_property(cell.piece, "position", cell.position, 0.25)\
		.set_trans(Tween.TRANS_QUAD).from(Vector2(cell.position.x, cell.position.y - fall_distance))

	await tween.finished


func spawn_pieces(cells: Array[Match3GridCell]) -> void:
	var filled: Array[Match3GridCell] = []
	for cell in cells:
		if cell != null and cell.has_piece():
			filled.append(cell)
	if filled.is_empty():
		return

	if board.configuration.fill_mode_is_in_place():
		await _spawn_in_place(filled)
		return

	var tween: Tween = create_tween().set_parallel(true)
	var fall_distance: float = board.configuration.cell_size.y * board.configuration.grid_height

	for cell in filled:
		cell.piece.hide()
		tween.tween_property(cell.piece, "visible", true, 0.1)
		tween.tween_property(cell.piece, "position", cell.position, 0.25)\
			.set_trans(Tween.TRANS_QUAD).from(Vector2(cell.position.x, cell.position.y - fall_distance))

	await tween.finished


func _spawn_in_place(cells: Array[Match3GridCell]) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	for cell in cells:
		var piece: Match3Piece = cell.piece
		var final_scale: Vector2 = piece.scale
		var final_alpha: float = piece.modulate.a

		piece.position = cell.position
		piece.scale = final_scale * 0.65
		piece.modulate.a = 0.0
		piece.show()

		tween.tween_property(piece, "scale", final_scale, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "modulate:a", final_alpha, 0.2)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished


func trigger_special_piece(piece: Match3Piece) -> void:
	if is_instance_valid(piece):
		match piece.id:
			&"special-blue-triangle":
				var tween: Tween = create_tween()
				tween.tween_property(piece, "scale", Vector2(piece.scale.x * 1.2, piece.scale.y * 1.5), 1.0)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				
				await tween.finished
			&"special-blue-triangle-5":
				var tween: Tween = create_tween()
				tween.tween_property(piece, "rotation", TAU, 0.5).set_ease(Tween.EASE_IN)
				tween.set_loops(2)
				
				await tween.loop_finished
				

func piece_drag_ended(piece: Match3Piece) -> void:
	if is_instance_valid(piece):
		var tween: Tween = create_tween()
		tween.tween_property(piece, "position", piece.cell.position, 0.25)\
			.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
			
		await tween.finished
		
	
func shuffle(movements: Array[Match3Shuffler.ShuffleMovement]) -> void:
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement in movements:
			tween.tween_property(movement.from_cell.piece, "position", movement.to_cell.position, 0.4)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(movement.to_cell.piece, "position", movement.from_cell.position, 0.4)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		await tween.finished
