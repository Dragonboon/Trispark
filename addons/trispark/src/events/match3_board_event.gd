class_name Match3BoardEvent
extends RefCounted
## Read-only-by-convention snapshot emitted by Match3Board.
## PIECES_DRAWN precedes initial-match cleanup; SEQUENCE_CONSUMED is emitted
## before the matched pieces are removed. Do not retain piece references after consumption.

enum Type {
	PIECES_DRAWN,
	STATE_CHANGED,
	PIECE_CREATED,
	PIECE_SELECTED,
	PIECE_UNSELECTED,
	PIECE_DRAG_STARTED,
	PIECE_DRAG_FINISHED,
	PIECE_QUEUED,
	PIECE_TRIGGERED,
	SWAP_ACCEPTED,
	SWAP_REJECTED,
	SEQUENCE_CONSUMED,
	SHUFFLE_STARTED,
	SHUFFLE_FINISHED,
	MOVE_CONSUMED,
	OUT_OF_MOVES,
}

var type: Type
var board: Node2D
var piece: Match3Piece
var cell: Match3GridCell
var other_cell: Match3GridCell
var sequence: Match3Sequence
var previous_state: int = -1
var new_state: int = -1
var moves_remaining: int = -1
var world_position: Vector2 = Vector2.ZERO
var timestamp_msec: int = 0

func _init(event_type: Type = Type.PIECES_DRAWN) -> void:
	type = event_type
	timestamp_msec = Time.get_ticks_msec()


func get_type_name() -> StringName:
	return StringName(Type.keys()[int(type)])
