class_name Match3SequenceDetector extends RefCounted
## Finds contiguous runs without bridging gaps or truncating a long match.

var board: Match3Board

func _init(owner: Match3Board) -> void:
	board = owner


func _scan(cells: Array[Match3GridCell], shape: Match3Sequence.Shapes) -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	var run: Array[Match3GridCell] = []
	var previous: Match3GridCell
	for cell in cells:
		if not cell.can_contain_piece or not cell.has_piece():
			_flush(run, shape, sequences)
			run.clear()
			previous = null
			continue
		if previous != null and not cell.piece.match_with(previous.piece):
			_flush(run, shape, sequences)
			run.clear()
		run.append(cell)
		previous = cell
	_flush(run, shape, sequences)
	return sequences


func _flush(run: Array[Match3GridCell], shape: Match3Sequence.Shapes, output: Array[Match3Sequence]) -> void:
	if run.size() >= board.configuration.min_match:
		output.append(Match3Sequence.new(run.duplicate(), shape))


func find_horizontal_sequences(cells: Array[Match3GridCell]) -> Array[Match3Sequence]:
	if not board.configuration.horizontal_shape:
		return []
	return _scan(cells, Match3Sequence.Shapes.Horizontal)


func find_vertical_sequences(cells: Array[Match3GridCell]) -> Array[Match3Sequence]:
	if not board.configuration.vertical_shape:
		return []
	return _scan(cells, Match3Sequence.Shapes.Vertical)


func find_horizontal_board_sequences() -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	for row in range(board.configuration.grid_height):
		sequences.append_array(find_horizontal_sequences(board.finder.cells_from_row(row)))
	return sequences


func find_vertical_board_sequences() -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	for column in range(board.configuration.grid_width):
		sequences.append_array(find_vertical_sequences(board.finder.cells_from_column(column)))
	return sequences


func find_diagonal_board_sequences() -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	if not board.configuration.diagonal_shape:
		return sequences
	var width := board.configuration.grid_width
	var height := board.configuration.grid_height
	for direction in [-1, 1]:
		for column in range(width):
			var cells: Array[Match3GridCell] = []
			var x := column
			var y := height - 1 if direction == -1 else 0
			while x >= 0 and x < width and y >= 0 and y < height:
				cells.append(board.finder.get_cell(x, y))
				x += 1
				y += direction
			sequences.append_array(_scan(cells, Match3Sequence.Shapes.Diagonal))
		for row in range(1, height):
			var cells: Array[Match3GridCell] = []
			var x := 0
			var y := height - 1 - row if direction == -1 else row
			while x < width and y >= 0 and y < height:
				cells.append(board.finder.get_cell(x, y))
				x += 1
				y += direction
			sequences.append_array(_scan(cells, Match3Sequence.Shapes.Diagonal))
	return sequences


func _intersection(a: Match3Sequence, b: Match3Sequence) -> Match3GridCell:
	for cell in a.cells:
		if b.cells.has(cell):
			return cell
	return null


func _combine(a: Match3Sequence, b: Match3Sequence, shape: Match3Sequence.Shapes) -> Match3Sequence:
	return Match3Sequence.new(a.cells + b.cells, shape)


func find_lshape_sequence(a: Match3Sequence, b: Match3Sequence) -> Match3Sequence:
	if not board.configuration.lshape:
		return null
	var h: Match3Sequence = a if a.is_horizontal_shape() else b
	var v: Match3Sequence = a if a.is_vertical_shape() else b
	if not h.is_horizontal_shape() or not v.is_vertical_shape():
		return null
	var cell := _intersection(h, v)
	if cell == null:
		return null
	if (cell == h.cells.front() or cell == h.cells.back()) and (cell == v.cells.front() or cell == v.cells.back()):
		return _combine(h, v, Match3Sequence.Shapes.LShape)
	return null


func find_tshape_sequence(a: Match3Sequence, b: Match3Sequence) -> Match3Sequence:
	if not board.configuration.tshape:
		return null
	var h: Match3Sequence = a if a.is_horizontal_shape() else b
	var v: Match3Sequence = a if a.is_vertical_shape() else b
	if not h.is_horizontal_shape() or not v.is_vertical_shape():
		return null
	var cell := _intersection(h, v)
	if cell == null:
		return null
	if not ((cell == h.cells.front() or cell == h.cells.back()) and (cell == v.cells.front() or cell == v.cells.back())):
		return _combine(h, v, Match3Sequence.Shapes.TShape)
	return null


func find_board_sequences() -> Array[Match3Sequence]:
	var horizontal := find_horizontal_board_sequences()
	var vertical := find_vertical_board_sequences()
	var sequences: Array[Match3Sequence] = []
	var used_horizontal: Dictionary = {}
	var used_vertical: Dictionary = {}
	for h in horizontal:
		for v in vertical:
			if used_horizontal.has(h) or used_vertical.has(v):
				continue
			var compound := find_lshape_sequence(h, v)
			if compound == null:
				compound = find_tshape_sequence(h, v)
			if compound != null:
				sequences.append(compound)
				used_horizontal[h] = true
				used_vertical[v] = true
	for h in horizontal:
		if not used_horizontal.has(h):
			sequences.append(h)
	for v in vertical:
		if not used_vertical.has(v):
			sequences.append(v)
	sequences.append_array(find_diagonal_board_sequences())
	return sequences


func find_match_from_piece(piece: Match3Piece) -> Match3Sequence:
	return find_match_from_cell(piece.cell)


func find_match_from_cell(cell: Match3GridCell) -> Match3Sequence:
	if cell == null or not cell.has_piece():
		return null
	for sequence in find_board_sequences():
		if sequence.cells.has(cell):
			return sequence
	return null
