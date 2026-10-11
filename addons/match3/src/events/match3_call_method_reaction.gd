@tool
class_name Match3CallMethodReaction
extends Match3Reaction
## No-code integration: invoke a method on a scene node.
## Paths resolve relative to Match3Board, e.g. "../HUD".

@export var target_path: NodePath
@export var method_name: StringName = &""
## When true, the callback receives one Match3BoardEvent argument.
@export var pass_event: bool = true


func react(board: Node2D, event: Match3BoardEvent) -> void:
	if not is_instance_valid(board) or target_path.is_empty() or method_name.is_empty():
		return
	var target := board.get_node_or_null(target_path)
	if target == null or not target.has_method(method_name):
		push_warning("Match3: Missing method '%s' at '%s'." % [method_name, target_path])
		return
	if pass_event:
		target.call(method_name, event)
	else:
		target.call(method_name)
