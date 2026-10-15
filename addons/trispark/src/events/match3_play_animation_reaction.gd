@tool
class_name Match3PlayAnimationReaction
extends Match3Reaction
## Plays a host scene AnimationPlayer when an event matches this Resource.

@export_node_path("AnimationPlayer") var player_path: NodePath
@export var animation_name: StringName = &""
@export_range(-1.0, 2.0, 0.05) var blend_time: float = -1.0
@export_range(0.1, 4.0, 0.05) var speed: float = 1.0


func react(board: Node2D, _event: Match3BoardEvent) -> void:
	if not is_instance_valid(board) or player_path.is_empty() or animation_name.is_empty():
		return
	var player := board.get_node_or_null(player_path) as AnimationPlayer
	if player == null or not player.has_animation(animation_name):
		push_warning("Match3: Animation '%s' unavailable at '%s'." % [animation_name, player_path])
		return
	player.play(animation_name, blend_time, speed)
