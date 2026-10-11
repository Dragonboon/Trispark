extends SceneTree
## Verify that demo animations preserve InPlace cell positions in both flows.
## FallDown and Side keep the pre-existing top-of-board spawn animation.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var board := Match3Board.new()
	board.configuration = Match3BoardConfiguration.new()
	board.configuration.auto_start = false
	get_root().add_child(board)

	var animator := Match3DemoAnimator.new()
	animator.board = board
	board.add_child(animator)

	var first := Match3GridCell.new()
	first.position = Vector2(120, 260)
	var first_piece := Match3Piece.new()
	first_piece.position = first.position
	first.piece = first_piece

	var second := Match3GridCell.new()
	second.position = Vector2(175, 260)
	var second_piece := Match3Piece.new()
	second_piece.position = second.position
	second.piece = second_piece

	# A no-op position during the animation is required, not just a correct endpoint.
	board.configuration.fill_mode = Match3BoardConfiguration.BoardFillModes.InPlace
	animator.spawn_piece(first)
	await process_frame
	assert(first_piece.position == first.position, "Serial InPlace moved a gem.")
	await create_timer(0.3).timeout
	assert(first_piece.scale.is_equal_approx(Vector2.ONE))
	assert(is_equal_approx(first_piece.modulate.a, 1.0))

	var cells: Array[Match3GridCell] = [first, second]
	animator.spawn_pieces(cells)
	await process_frame
	assert(first_piece.position == first.position, "Parallel InPlace moved the first gem.")
	assert(second_piece.position == second.position, "Parallel InPlace moved the second gem.")
	await create_timer(0.3).timeout
	assert(first_piece.scale.is_equal_approx(Vector2.ONE))
	assert(second_piece.scale.is_equal_approx(Vector2.ONE))

	for mode in [Match3BoardConfiguration.BoardFillModes.FallDown, Match3BoardConfiguration.BoardFillModes.Side]:
		board.configuration.fill_mode = mode
		await animator.spawn_piece(first)
		assert(first_piece.position.is_equal_approx(first.position), "Serial falling refill misplaced a gem.")
		await animator.spawn_pieces(cells)
		assert(second_piece.position.is_equal_approx(second.position), "Parallel falling refill misplaced a gem.")

	print("Match3 fill animation regression: PASS")
	first_piece.free()
	second_piece.free()
	first.free()
	second.free()
	board.free()
	quit()
