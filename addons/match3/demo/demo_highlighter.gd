class_name Match3DemoHighlighter extends Match3Highlighter

## Swap this resource to change the highlight without writing another highlighter.
@export var highlight_texture: Texture2D = preload("res://addons/match3/demo/assets/highlighted.png")


func highlight_cells(cells: Array[Match3GridCell]) -> void:
	current_highlighted_cells = cells
	
	for cell in current_highlighted_cells:
		highlight_cell(cell)


func highlight_cell(cell: Match3GridCell) -> void:
	if cell.sprite_2d is Sprite2D and highlight_texture:
		cell.sprite_2d.texture = highlight_texture


func remove_highlight() -> void:
	for cell in current_highlighted_cells:
		if cell.sprite_2d and cell.sprite_2d is Sprite2D:
			cell.sprite_2d.texture = cell.original_texture
		
	current_highlighted_cells.clear()

	current_highlighted_pieces.clear()
