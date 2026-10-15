@tool
class_name Match3Reaction
extends Resource
## Optional reusable event reaction. Empty mask = all events.
## Treat shared Resource presets as immutable and store runtime state on scene nodes.

@export var enabled: bool = true
@export_flags(
	"Pieces Drawn", "State Changed", "Piece Created", "Piece Selected",
	"Piece Unselected", "Piece Drag Started", "Piece Drag Finished",
	"Piece Queued", "Piece Triggered", "Swap Accepted", "Swap Rejected",
	"Sequence Consumed", "Shuffle Started", "Shuffle Finished",
	"Move Consumed", "Out Of Moves"
) var event_mask: int = 0


static func mask_for(event_type: Match3BoardEvent.Type) -> int:
	return 1 << int(event_type)


func accepts(event: Match3BoardEvent) -> bool:
	return enabled and (event_mask == 0 or (event_mask & mask_for(event.type)) != 0)


## Override in a subclass. A reaction should not mutate the shared configuration.
func react(_board: Node2D, _event: Match3BoardEvent) -> void:
	pass
