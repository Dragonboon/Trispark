@tool
class_name Match3AudioReaction
extends Match3Reaction
## Optional fire-and-forget sound; no persistent audio nodes or autoloads.

@export var stream: AudioStream
@export var spatial: bool = true
@export var bus: StringName = &"Master"
@export_range(-60.0, 12.0, 0.5) var volume_db: float = 0.0
@export_range(0.25, 3.0, 0.05) var pitch_min: float = 1.0
@export_range(0.25, 3.0, 0.05) var pitch_max: float = 1.0


func react(board: Node2D, event: Match3BoardEvent) -> void:
	if stream == null or not is_instance_valid(board) or not board.is_inside_tree():
		return
	var scene := board.get_tree().current_scene
	var parent: Node = scene if scene != null else board
	var pitch: float = randf_range(minf(pitch_min, pitch_max), maxf(pitch_min, pitch_max))
	if spatial:
		var player := AudioStreamPlayer2D.new()
		parent.add_child(player)
		player.global_position = event.world_position
		player.stream = stream
		player.bus = bus
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.finished.connect(player.queue_free)
		player.play()
	else:
		var player := AudioStreamPlayer.new()
		parent.add_child(player)
		player.stream = stream
		player.bus = bus
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.finished.connect(player.queue_free)
		player.play()
