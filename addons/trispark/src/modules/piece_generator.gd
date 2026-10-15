class_name Match3PieceGenerator extends RefCounted
## Draws weighted configurations with per-board RNG.
## Never mutates shared Match3PieceWeight Resources or hangs with zero weights.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var available_pieces: Array[Match3PieceConfiguration] = []


func _init() -> void:
	rng.randomize()


## -1 uses a random seed. Nonnegative values are reproducible.
func set_seed(value: int) -> void:
	if value < 0:
		rng.randomize()
	else:
		rng.seed = value


func add_pieces(pieces: Array[Match3PieceConfiguration]) -> void:
	for piece: Match3PieceConfiguration in pieces:
		add_piece(piece)


func add_piece(piece: Match3PieceConfiguration) -> void:
	if piece != null and not available_pieces.has(piece):
		available_pieces.append(piece)


## Null means that exclusions or zero weights leave no valid candidate.
## The caller decides whether to skip a spawn or report a configuration error.
func roll(except: Array[Match3PieceConfiguration] = []) -> Match3PieceConfiguration:
	var total: float = 0.0
	for piece in available_pieces:
		if except.has(piece):
			continue
		total += _weight_of(piece)
	if total <= 0.0:
		return null

	var threshold: float = rng.randf() * total
	var running: float = 0.0
	var last_candidate: Match3PieceConfiguration
	for piece in available_pieces:
		if except.has(piece):
			continue
		var weight: float = _weight_of(piece)
		if weight <= 0.0:
			continue
		running += weight
		last_candidate = piece
		if threshold < running:
			return piece
	return last_candidate


func _weight_of(piece: Match3PieceConfiguration) -> float:
	if piece == null:
		return 0.0
	if piece.weight == null:
		return 1.0
	return maxf(0.0, piece.weight.current_weight)
