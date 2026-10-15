class_name Match3GridCell extends Node2D

const GroupName: StringName = &"grid_cells"

@export_category("Textures")
@export var texture_scale: float = 1.0
@export var odd_cell_texture: Texture2D
@export var even_cell_texture: Texture2D
@export var empty_cell_texture: Texture2D

var column: int = 0
var row: int = 0
var size: Vector2i = Vector2i(48, 48)
var can_contain_piece: bool = true

#region Cached neighbours
## The Match3Board assign this values when preparing the cells so that they are always available as a cache.
var neighbour_up: Match3GridCell
var neighbour_bottom: Match3GridCell
var neighbour_right: Match3GridCell
var neighbour_left: Match3GridCell
var diagonal_neighbour_top_right: Match3GridCell
var diagonal_neighbour_top_left: Match3GridCell
var diagonal_neighbour_bottom_right: Match3GridCell
var diagonal_neighbour_bottom_left: Match3GridCell
#endregion

## Could be Sprite2D or AnimatedSprite2D
var sprite_2d
var piece: Match3Piece:
	set(new_piece):
		if piece != new_piece:
			piece = new_piece
			
			if piece:
				piece.cell = self

var original_texture: Texture2D


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	name = "GridCellUI_[%d]_[%d]" % [column, row]


func _ready() -> void:
	_prepare_sprite()
	
	
func _prepare_sprite() -> void:
	sprite_2d = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite_2d == null:
		sprite_2d = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	if sprite_2d is Sprite2D:
		sprite_2d.texture = get_texture()
		
		if sprite_2d.texture:
			sprite_2d.scale = calculate_scale_texture_based_on_cell_size(sprite_2d.texture)
			original_texture = sprite_2d.texture
		
	elif sprite_2d is AnimatedSprite2D:
		sprite_2d.scale = calculate_scale_texture_based_on_cell_size(sprite_2d.get_sprite_2d_frames().get_frame(sprite_2d.animation, sprite_2d.get_frame()))
	

func has_piece() -> bool:
	return piece != null
	

func is_empty() -> bool:
	return piece == null


func clear(disable: bool = false) -> void:
	remove_piece()
	can_contain_piece = not disable


func remove_piece(queued: bool = false) -> void:
	if has_piece():
		if queued:
			piece.queue_free()
		else:
			piece.free()
			
	piece = null
		

func can_swap_piece_with_cell(other_cell: Match3GridCell) -> bool:
	return other_cell != self \
		and has_piece() \
		and other_cell.has_piece() \
		and piece != other_cell.piece \
		and piece.can_be_swapped \
		and other_cell.piece.can_be_swapped 


func swap_piece_with_cell(other_cell: Match3GridCell) -> bool:
	if can_swap_piece_with_cell(other_cell):
		var current_piece: Match3Piece = piece
		piece = other_cell.piece
		other_cell.piece = current_piece
		
		return true
			
	return false
#
#
func calculate_scale_texture_based_on_cell_size(texture: Texture2D) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale
	
	
func get_texture() -> Texture2D:
	if not can_contain_piece:
		return empty_cell_texture
	
	if even_cell_texture and odd_cell_texture:
		return even_cell_texture if (column + row) % 2 == 0 else odd_cell_texture
	elif even_cell_texture and odd_cell_texture == null:
		return even_cell_texture
	elif odd_cell_texture and even_cell_texture == null:
		return odd_cell_texture
	
	return empty_cell_texture

#region Grid position
func board_position() -> Vector2i:
	return Vector2i(column, row)


func in_same_row_as(other_cell: Match3GridCell) -> bool:
	return row == other_cell.row


func in_same_column_as(other_cell: Match3GridCell) -> bool:
	return column == other_cell.column


func in_same_position_as(other_cell: Match3GridCell) -> bool:
	return in_same_column_as(other_cell) and in_same_row_as(other_cell)


func in_same_grid_position_as(grid_position: Vector2i) -> bool:
	return grid_position.x == column and grid_position.y == row

#endregion

#region Neighbours
func is_row_neighbour_of(other_cell: Match3GridCell) -> bool:
	var left_column: int = column - 1
	var right_column: int = column + 1
	
	return in_same_row_as(other_cell) \
		and [left_column, right_column].any(func(near_column: int): 
			return other_cell.column == near_column)


func is_column_neighbour_of(other_cell: Match3GridCell) -> bool:
	var upper_row: int = row - 1
	var bottom_row: int = row + 1

	return in_same_column_as(other_cell) \
		and [upper_row, bottom_row].any(func(near_row: int): return other_cell.row == near_row)


func is_adjacent_to(other_cell: Match3GridCell, check_diagonal: bool = false) -> bool:
	return is_row_neighbour_of(other_cell) \
		or is_column_neighbour_of(other_cell) \
		or (check_diagonal and in_diagonal_with(other_cell))
	
	
func is_diagonal_adjacent_to(other_cell: Match3GridCell) -> bool:
	return is_adjacent_to(other_cell, true)


func in_diagonal_with(other_cell: Match3GridCell) -> bool:
	var diagonal_top_right: Vector2i = Vector2i(column + 1, row - 1)
	var diagonal_top_left: Vector2i = Vector2i( column - 1, row - 1)
	var diagonal_bottom_right: Vector2i = Vector2i( column + 1, row + 1)
	var diagonal_bottom_left: Vector2i = Vector2i(column - 1, row + 1)

	return other_cell.in_same_grid_position_as(diagonal_top_right) \
		or other_cell.in_same_grid_position_as(diagonal_top_left) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_right) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_left)


func neighbours() -> Dictionary:
	return {
		"up": neighbour_up,
		"bottom": neighbour_bottom,
		"right": neighbour_right,
		"left": neighbour_left,
		"diagonal_top_right": diagonal_neighbour_top_right,
		"diagonal_top_left": diagonal_neighbour_top_left,
		"diagonal_bottom_right": diagonal_neighbour_bottom_right,
		"diagonal_bottom_left": diagonal_neighbour_bottom_left,
	}

## Return cells that can contain pieces and is not empty
func usable_neighbours() -> Dictionary:
	var current_neighbours: Dictionary = neighbours()
	
	for position_key: String in current_neighbours:
		var cell = current_neighbours[position_key]
		
		if cell and (not cell.can_contain_piece or cell.is_empty()):
			current_neighbours[position_key] = null
	
	return current_neighbours


func neighbour_up_has_piece() -> bool:
	return neighbour_up and neighbour_up.has_piece()


func neighbour_bottom_has_piece() -> bool:
	return neighbour_bottom and neighbour_bottom.has_piece()


func neighbour_right_has_piece() -> bool:
	return neighbour_right and neighbour_right.has_piece()


func neighbour_left_has_piece() -> bool:
	return neighbour_left and neighbour_left.has_piece()


func diagonal_neighbour_bottom_left_has_piece() -> bool:
	return diagonal_neighbour_bottom_left and diagonal_neighbour_bottom_left.has_piece()


func diagonal_neighbour_bottom_right_has_piece() -> bool:
	return diagonal_neighbour_bottom_right and diagonal_neighbour_bottom_right.has_piece()


func diagonal_neighbour_top_left_has_piece() -> bool:
	return diagonal_neighbour_top_left and diagonal_neighbour_top_left.has_piece()


func diagonal_neighbour_top_right_has_piece() -> bool:
	return diagonal_neighbour_top_right and diagonal_neighbour_top_right.has_piece()


func neighbour_bottom_is_empty() -> bool:
	return neighbour_bottom and neighbour_bottom.is_empty()


func neighbour_right_is_empty() -> bool:
	return neighbour_right and neighbour_right.is_empty()


func neighbour_left_is_empty() -> bool:
	return neighbour_left and neighbour_left.is_empty()


func diagonal_neighbour_bottom_left_is_empty() -> bool:
	return diagonal_neighbour_bottom_left and diagonal_neighbour_bottom_left.is_empty()


func diagonal_neighbour_bottom_right_is_empty() -> bool:
	return diagonal_neighbour_bottom_right and diagonal_neighbour_bottom_right.is_empty()


func diagonal_neighbour_top_left_is_empty() -> bool:
	return diagonal_neighbour_top_left and diagonal_neighbour_top_left.is_empty()


func diagonal_neighbour_top_right_is_empty() -> bool:
	return diagonal_neighbour_top_right and diagonal_neighbour_top_right.is_empty()


func is_top_left_corner() -> bool:
	return neighbour_up == null and neighbour_left == null \
		and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell
		

func is_top_right_corner() -> bool:
	return neighbour_up == null and neighbour_right == null \
		and neighbour_bottom is Match3GridCell and neighbour_left is Match3GridCell
		

func is_bottom_left_corner() -> bool:
	return neighbour_bottom == null and neighbour_left == null \
		and neighbour_up is Match3GridCell and neighbour_right is Match3GridCell
		

func is_bottom_right_corner() -> bool:
	return neighbour_bottom == null and neighbour_right == null \
		and neighbour_up is Match3GridCell and neighbour_left is Match3GridCell


func is_top_border() -> bool:
	return (is_top_left_corner() or is_top_right_corner()) \
		or (neighbour_up == null and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell and neighbour_left is Match3GridCell)
		

func is_bottom_border() -> bool:
	return (is_bottom_left_corner() or is_bottom_right_corner()) \
	or (neighbour_bottom == null and neighbour_up is Match3GridCell and neighbour_right is Match3GridCell and neighbour_left is Match3GridCell)
		

func is_right_border() -> bool:
	return (is_top_right_corner() or is_bottom_right_corner()) \
		or (neighbour_right == null and neighbour_up is Match3GridCell and neighbour_bottom is Match3GridCell and neighbour_left is Match3GridCell)
					
	
func is_left_border() -> bool:
	return (is_top_left_corner() or is_bottom_left_corner()) \
		or (neighbour_left == null and neighbour_up is Match3GridCell and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell)
#endregion
