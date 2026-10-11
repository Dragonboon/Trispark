class_name Match3Animator extends Node


#region Animation names
const DrawPiecesAnimation: StringName = &"draw-pieces"
const DrawCellsAnimation: StringName = &"draw-cells"
const SwapPiecesAnimation: StringName = &"swap-pieces"
const SwapRejectedPiecesAnimation: StringName = &"swap-rejected-pieces"
const ConsumeSequenceAnimation: StringName = &"consume-sequence"
const ConsumeSequencesAnimation: StringName = &"consume-sequences"
const FallPieceAnimation: StringName = &"fall-piece"
const FallPiecesAnimation: StringName = &"fall-pieces"
const SpawnPieceAnimation: StringName = &"spawn-piece"
const SpawnPiecesAnimation: StringName = &"spawn-pieces"
const TriggerSpecialPieceAnimation: StringName = &"trigger-special-piece"
const PieceDragEndedAnimation: StringName = &"piece-drag-ended"
const ShufflePiecesAnimation: StringName = &"shuffle-pieces"
#endregion

signal animation_started(animation_name: StringName)
signal animation_finished(animation_name: StringName)

@export var board: Match3Board

var current_animation: StringName = &""
var animations: Dictionary = {
	DrawPiecesAnimation: draw_pieces,
	DrawCellsAnimation: draw_cells,
	SwapPiecesAnimation: swap_pieces,
	SwapRejectedPiecesAnimation: swap_rejected_pieces,
	ConsumeSequenceAnimation: consume_sequence,
	ConsumeSequencesAnimation: consume_sequences,
	FallPieceAnimation: fall_piece,
	FallPiecesAnimation: fall_pieces,
	SpawnPieceAnimation: spawn_piece,
	SpawnPiecesAnimation: spawn_pieces,
	TriggerSpecialPieceAnimation: trigger_special_piece,
	PieceDragEndedAnimation: piece_drag_ended,
	ShufflePiecesAnimation: shuffle

}

func _ready() -> void:
	if board == null:
		board = get_tree().get_first_node_in_group(Match3Board.GroupName)
	
	assert(board != null, "Match3Animator: This animator needs a Match3Board assigned")
	
	animation_started.connect(on_animation_started)
	animation_finished.connect(on_animation_finished)


func run(anim_name: StringName, parameters: Array[Variant]) -> void:
	animation_started.emit(anim_name)
	
	if animations.has(anim_name):
		await animations[anim_name].callv(parameters)
		
	animation_finished.emit(anim_name)


#region Overridables
func draw_cells(cells: Array[Match3GridCell]) -> void:
	pass


func draw_pieces(pieces: Array[Match3Piece]) -> void:
	pass


func swap_pieces(
	from_piece: Match3Piece,
	to_piece: Match3Piece,
	from_piece_position: Vector2,
	to_piece_position: Vector2
):
	pass


func swap_rejected_pieces(
	from_piece: Match3Piece,
	to_piece: Match3Piece,
	from_piece_position: Vector2,
	to_piece_position: Vector2
):
	pass
	
	
func consume_sequence(sequence: Match3Sequence) -> void:
	pass


func consume_sequences(sequences: Array[Match3SequenceConsumer.Match3SequenceConsumeResult]) -> void:
	pass


func fall_piece(movement: Match3FallMover.FallMovement) -> void:
	pass
	

func fall_pieces(movements: Array[Match3FallMover.FallMovement]) -> void:
	pass
	
	
func spawn_piece(cell: Match3GridCell) -> void:
	pass
	

func spawn_pieces(cells: Array[Match3GridCell]) -> void:
	pass
	
	
func trigger_special_piece(piece: Match3Piece) -> void:
	pass


func piece_drag_ended(piece: Match3Piece) -> void:
	pass


func shuffle(movements: Array[Match3Shuffler.ShuffleMovement]) -> void:
	pass

#endregion

#region Signal callbacks
func on_animation_started(animation_name: StringName) -> void:
	current_animation = animation_name


func on_animation_finished(animation_name: StringName) -> void:
	current_animation = &""

#endregion
