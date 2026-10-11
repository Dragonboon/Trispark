class_name Match3Highlighter extends Node

@export var board: Match3Board

var current_highlighted_cells: Array[Match3GridCell] = []
var current_highlighted_pieces: Array[Match3Piece] = []


func _ready() -> void:
	if board == null:
		board = get_tree().get_first_node_in_group(Match3Board.GroupName)
	
	board.locked.connect(on_board_locked)
	board.selected_piece.connect(on_selected_piece)
	board.unselected_piece.connect(on_unselected_piece)
	board.piece_drag_started.connect(on_selected_piece)
	board.piece_drag_ended.connect(on_unselected_piece)
	
	if board.line_connector:
		board.line_connector.connected_piece.connect(on_connected_piece)
		board.line_connector.confirmed_match.connect(on_confirmed_line_connector_match)
		board.line_connector.canceled_match.connect(on_canceled_line_connector_match)


func highlight_cells(cells: Array[Match3GridCell]) -> void:
	pass


func highlight_cell(cell: Match3GridCell) -> void:
	pass


func remove_highlight() -> void:
	pass

#region Signal callbacks
func on_board_locked() -> void:
	remove_highlight()
	
	
func on_selected_piece(piece: Match3Piece) -> void:
	if piece.is_special() and piece.can_be_triggered:
		return
	

func on_unselected_piece(_piece: Match3Piece) -> void:
	remove_highlight()


func on_connected_piece(_piece: Match3Piece) -> void:
	pass


func on_confirmed_line_connector_match(_pieces: Array[Match3Piece]) -> void:
	remove_highlight()


func on_canceled_line_connector_match(_pieces: Array[Match3Piece]) -> void:
	remove_highlight()

#endregion
