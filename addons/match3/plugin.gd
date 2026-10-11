@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree() -> void:
	inspector_plugin = preload("res://addons/match3/inspector/inspector_button_plugin.gd").new()
	add_inspector_plugin(inspector_plugin)
	
	add_custom_type("Match3Board", "Node2D", preload("res://addons/match3/src/match3_board.gd"), preload("assets/board.svg"))
	add_custom_type("Match3BoardPreview", "Node2D", preload("res://addons/match3/src/tools/match3_preview.gd"), preload("assets/board_preview.svg"))
	add_custom_type("Match3Animator", "Node2D", preload("res://addons/match3/src/ui/match3_animator.gd"), preload("assets/animator.svg"))
	add_custom_type("Match3Highlighter", "Node2D", preload("res://addons/match3/src/ui/match3_highlighter.gd"), preload("assets/light.svg"))
	add_custom_type("Match3LineConnector", "Node2D", preload("res://addons/match3/src/pieces/line_connector.gd"), null)
	

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)

	remove_custom_type("Match3LineConnector")
	remove_custom_type("Match3Highlighter")
	remove_custom_type("Match3Animator")
	remove_custom_type("Match3BoardPreview")
	remove_custom_type("Match3Board")
